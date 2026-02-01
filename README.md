# FFmpegMinimal

Minimal FFmpeg build with only WMA decoder support (~2-4MB).

## Building the XCFrameworks

1. Clone FFmpeg-iOS:
```bash
git clone https://github.com/kewlbear/FFmpeg-iOS.git
cd FFmpeg-iOS
```

2. Build with minimal configuration:
```bash
swift run ffmpeg-ios build \
  --library avcodec --library avutil --library avformat --library swresample \
  --extra-options "--disable-everything \
    --enable-decoder=wmav1 --enable-decoder=wmav2 \
    --enable-demuxer=asf \
    --enable-muxer=ipod \
    --enable-encoder=aac \
    --enable-protocol=file \
    --enable-filter=aresample \
    --disable-programs --disable-doc --disable-debug --enable-small"
```

3. Copy the resulting xcframeworks into `XCFrameworks/`:
   - `libavcodec.xcframework`
   - `libavformat.xcframework`
   - `libavutil.xcframework`
   - `libswresample.xcframework`

4. Add this local package to the Xcode project:
   - File > Add Package Dependencies > Add Local
   - Select this `FFmpegMinimal` directory
