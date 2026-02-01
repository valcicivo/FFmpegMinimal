# FFmpegMinimal

Minimal FFmpeg build for iOS with only WMA audio decoding support. Used by the [VoiceText](https://github.com/valcicivo) app to convert WMA files to M4A on-device before transcription.

## What's Included

Built from **FFmpeg 7.1** with `--disable-everything` and only these components enabled:

| Component | Type | Purpose |
|-----------|------|---------|
| wmav1, wmav2 | Decoders | WMA audio decoding |
| aac | Encoder | AAC output encoding |
| asf | Demuxer | WMA container format |
| ipod | Muxer | M4A container output |
| file | Protocol | Local file I/O |

Libraries included: `libavcodec`, `libavformat`, `libavutil`, `libswresample`

Excluded: avdevice, avfilter, swscale, postproc, network, all video codecs, all other audio codecs.

## Installation (SPM)

Add this package in Xcode:

1. **File > Add Package Dependencies**
2. Enter: `https://github.com/valcicivo/FFmpegMinimal`
3. Set version to **0.1.0** (or branch: `main`)

Or add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/valcicivo/FFmpegMinimal", from: "0.1.0")
]
```

Then import in Swift:

```swift
import FFmpegMinimal
```

All FFmpeg C APIs (`avformat_open_input`, `avcodec_find_decoder`, `swr_convert`, etc.) are available directly.

## Size

- Compressed (zip): ~3.2 MB
- Uncompressed (xcframework): ~8.6 MB (3 architectures)
- App binary impact: ~2-3 MB (single architecture slice)

## Architectures

- `ios-arm64` (device)
- `ios-arm64_x86_64-simulator` (Apple Silicon + Intel simulators)

## Rebuilding the XCFrameworks

If you need to rebuild from source (e.g., to add codecs or update FFmpeg):

```bash
./build-ffmpeg.sh
```

This script will:
1. Download FFmpeg 7.1 source
2. Cross-compile for iOS device (arm64) and simulator (arm64 + x86_64)
3. Merge into a single `FFmpegMinimal.xcframework`
4. Output to `XCFrameworks/`

After rebuilding, create a new release:

```bash
# Zip the xcframework
zip -r FFmpegMinimal.xcframework.zip XCFrameworks/FFmpegMinimal.xcframework

# Compute new checksum for Package.swift
swift package compute-checksum FFmpegMinimal.xcframework.zip

# Update the checksum in Package.swift, then:
gh release create <version> FFmpegMinimal.xcframework.zip --title "<version>"
```

## Requirements

- iOS 16.2+
- Xcode 15+
- Swift 5.9+
