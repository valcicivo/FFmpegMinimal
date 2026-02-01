#!/bin/bash
# Build minimal FFmpeg xcframeworks for iOS (WMA decoder only)
# Created by Ivo Valcic
#
# Usage: ./build-ffmpeg.sh
# Output: XCFrameworks/ directory with libavcodec, libavformat, libavutil, libswresample

set -e

FFMPEG_VERSION="7.1"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/.ffmpeg-build"
OUTPUT_DIR="${SCRIPT_DIR}/XCFrameworks"
DEPLOYMENT_TARGET="16.2"

COMMON_FLAGS="--disable-everything \
  --enable-decoder=wmav1 --enable-decoder=wmav2 \
  --enable-demuxer=asf \
  --enable-muxer=ipod \
  --enable-encoder=aac \
  --enable-protocol=file \
  --enable-filter=aresample \
  --disable-programs --disable-doc --disable-debug \
  --enable-small --disable-asm \
  --enable-cross-compile --target-os=darwin \
  --disable-avdevice --disable-swscale --disable-avfilter \
  --disable-postproc --disable-network \
  --disable-autodetect"

LIBS="libavcodec libavformat libavutil libswresample"

echo "=== Building minimal FFmpeg ${FFMPEG_VERSION} for iOS ==="

# Clean previous build
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"
cd "${BUILD_DIR}"

# Download FFmpeg source
if [ ! -d "ffmpeg-${FFMPEG_VERSION}" ]; then
    echo "--- Downloading FFmpeg ${FFMPEG_VERSION} ---"
    curl -L "https://ffmpeg.org/releases/ffmpeg-${FFMPEG_VERSION}.tar.xz" -o ffmpeg.tar.xz
    tar xf ffmpeg.tar.xz
    rm ffmpeg.tar.xz
fi

FFMPEG_SRC="${BUILD_DIR}/ffmpeg-${FFMPEG_VERSION}"

build_arch() {
    local ARCH=$1
    local SDK=$2
    local PREFIX="${BUILD_DIR}/install-${SDK}-${ARCH}"
    local SDK_PATH=$(xcrun --sdk ${SDK} --show-sdk-path)
    local CC="xcrun --sdk ${SDK} clang"

    echo ""
    echo "--- Building for ${SDK} ${ARCH} ---"

    mkdir -p "${BUILD_DIR}/build-${SDK}-${ARCH}"
    cd "${BUILD_DIR}/build-${SDK}-${ARCH}"

    local EXTRA_CFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -mios-version-min=${DEPLOYMENT_TARGET}"
    local EXTRA_LDFLAGS="-arch ${ARCH} -isysroot ${SDK_PATH} -mios-version-min=${DEPLOYMENT_TARGET}"

    if [ "${SDK}" = "iphonesimulator" ]; then
        EXTRA_CFLAGS="${EXTRA_CFLAGS} -miphonesimulator-version-min=${DEPLOYMENT_TARGET}"
        EXTRA_LDFLAGS="${EXTRA_LDFLAGS} -miphonesimulator-version-min=${DEPLOYMENT_TARGET}"
    fi

    ${FFMPEG_SRC}/configure \
        --prefix="${PREFIX}" \
        --arch="${ARCH}" \
        --cc="${CC}" \
        --sysroot="${SDK_PATH}" \
        --extra-cflags="${EXTRA_CFLAGS}" \
        --extra-ldflags="${EXTRA_LDFLAGS}" \
        --enable-pic \
        --enable-static \
        --disable-shared \
        ${COMMON_FLAGS}

    make -j$(sysctl -n hw.ncpu)
    make install
    cd "${BUILD_DIR}"
}

# Build for iOS device (arm64)
build_arch arm64 iphoneos

# Build for iOS simulator (arm64 for Apple Silicon)
build_arch arm64 iphonesimulator

# Also build x86_64 simulator for Rosetta support
build_arch x86_64 iphonesimulator

# Create fat simulator libraries
echo ""
echo "--- Creating fat simulator libraries ---"
SIMULATOR_FAT="${BUILD_DIR}/install-simulator-fat"
mkdir -p "${SIMULATOR_FAT}/lib"
cp -R "${BUILD_DIR}/install-iphonesimulator-arm64/include" "${SIMULATOR_FAT}/"

for lib in ${LIBS}; do
    LIB_NAME="${lib#lib}.a"  # e.g. libavcodec -> avcodec.a
    # Check both naming conventions
    if [ -f "${BUILD_DIR}/install-iphonesimulator-arm64/lib/${lib}.a" ]; then
        LIB_FILE="${lib}.a"
    elif [ -f "${BUILD_DIR}/install-iphonesimulator-arm64/lib/lib${lib}.a" ]; then
        LIB_FILE="lib${lib}.a"
    else
        # Find the actual file
        LIB_FILE=$(basename "$(ls ${BUILD_DIR}/install-iphonesimulator-arm64/lib/*${lib#lib}*.a 2>/dev/null | head -1)")
    fi

    echo "  Merging simulator slices for ${LIB_FILE}"
    lipo -create \
        "${BUILD_DIR}/install-iphonesimulator-arm64/lib/${LIB_FILE}" \
        "${BUILD_DIR}/install-iphonesimulator-x86_64/lib/${LIB_FILE}" \
        -output "${SIMULATOR_FAT}/lib/${LIB_FILE}"
done

# Create xcframeworks
echo ""
echo "--- Creating xcframeworks ---"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}"

for lib in ${LIBS}; do
    # Find actual library filename
    if [ -f "${BUILD_DIR}/install-iphoneos-arm64/lib/${lib}.a" ]; then
        LIB_FILE="${lib}.a"
    else
        LIB_FILE=$(basename "$(ls ${BUILD_DIR}/install-iphoneos-arm64/lib/*${lib#lib}*.a 2>/dev/null | head -1)")
    fi

    FRAMEWORK_NAME="${lib}"
    echo "  Creating ${FRAMEWORK_NAME}.xcframework"

    # Create per-library header directories so headers don't conflict across xcframeworks
    DEVICE_HEADERS="${BUILD_DIR}/headers-device-${lib}"
    SIM_HEADERS="${BUILD_DIR}/headers-sim-${lib}"
    rm -rf "${DEVICE_HEADERS}" "${SIM_HEADERS}"
    mkdir -p "${DEVICE_HEADERS}/${lib}"
    mkdir -p "${SIM_HEADERS}/${lib}"
    cp -R "${BUILD_DIR}/install-iphoneos-arm64/include/${lib}/"* "${DEVICE_HEADERS}/${lib}/"
    cp -R "${SIMULATOR_FAT}/include/${lib}/"* "${SIM_HEADERS}/${lib}/"

    xcodebuild -create-xcframework \
        -library "${BUILD_DIR}/install-iphoneos-arm64/lib/${LIB_FILE}" \
        -headers "${DEVICE_HEADERS}" \
        -library "${SIMULATOR_FAT}/lib/${LIB_FILE}" \
        -headers "${SIM_HEADERS}" \
        -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
done

# Add module maps so Swift can import the libraries
echo ""
echo "--- Adding module maps ---"
for lib in ${LIBS}; do
    for slice_dir in "${OUTPUT_DIR}/${lib}.xcframework"/ios-*; do
        HEADERS_DIR="${slice_dir}/Headers"
        cat > "${HEADERS_DIR}/module.modulemap" << MAPEOF
module ${lib} {
    umbrella "${lib}"
    link "${lib#lib}"
    export *
}
MAPEOF
        echo "  Added module.modulemap to $(basename ${slice_dir})"
    done
done

echo ""
echo "=== Build complete ==="
echo "XCFrameworks created in: ${OUTPUT_DIR}"
ls -lh "${OUTPUT_DIR}"

# Show total size
echo ""
echo "Total size:"
du -sh "${OUTPUT_DIR}"

# Cleanup build directory
echo ""
echo "Cleaning up build files..."
rm -rf "${BUILD_DIR}"
echo "Done!"
