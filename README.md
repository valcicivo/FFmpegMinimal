# FFmpegMinimal

Minimal FFmpeg build for iOS — converts WMA audio files to M4A on-device.

## What's Included

Built from **FFmpeg 7.1** with `--disable-everything` and only these components enabled:

| Component | Type | Purpose |
|-----------|------|---------|
| wmav1, wmav2 | Decoders | WMA audio decoding |
| aac | Encoder | AAC output encoding |
| asf | Demuxer | WMA container format |
| ipod | Muxer | M4A container output |
| file | Protocol | Local file I/O |

Libraries: `libavcodec`, `libavformat`, `libavutil`, `libswresample`

## Installation (SPM)

Add in Xcode via **File > Add Package Dependencies**:

```
https://github.com/valcicivo/FFmpegMinimal
```

Or in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/valcicivo/FFmpegMinimal", from: "0.1.0")
]
```

Then `import FFmpegMinimal` to access the FFmpeg C APIs.

## Size

- Compressed: ~3.2 MB
- App binary impact: ~2-3 MB (single architecture)

## Rebuilding

To rebuild from source (e.g., to update FFmpeg or add codecs):

```bash
./build-ffmpeg.sh
```

Then create a new release:

```bash
zip -r FFmpegMinimal.xcframework.zip XCFrameworks/FFmpegMinimal.xcframework
swift package compute-checksum FFmpegMinimal.xcframework.zip
# Update checksum in Package.swift, then:
gh release create <version> FFmpegMinimal.xcframework.zip --title "<version>"
```

## Requirements

- iOS 16.2+
- Xcode 15+
- Swift 5.9+
