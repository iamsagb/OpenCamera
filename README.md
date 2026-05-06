<div align="center">

# 📸 OpenCamera

**The complete iOS camera SDK — every AVFoundation feature, one clean Swift API.**

[![Swift Package Manager](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat-square)](https://swift.org/package-manager/)
[![Platform](https://img.shields.io/badge/platform-iOS%2015%2B-blue.svg?style=flat-square)]()
[![Swift](https://img.shields.io/badge/Swift-5.10-orange.svg?style=flat-square)](https://swift.org)
[![Xcode](https://img.shields.io/badge/Xcode-15%2B-1575F9.svg?style=flat-square)]()
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](LICENSE)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)]()

*Photos · Video · RAW · Live Photos · Depth · Portrait · Manual mode · Multi-lens · Real-time filters*

</div>

---

## ✨ Why OpenCamera?

`AVFoundation` is powerful, but every camera app re-implements the same 1,500 lines of session plumbing, photo delegates, and manual-control gymnastics. **OpenCamera** ships that boilerplate — battle-tested and modular — so you can build the *camera you actually want* in a few hundred lines of SwiftUI.

```swift
let session = OpenCamera.makeSession(.defaultPhoto)
try await session.prepare()
try await session.start()

let photo = try await session.photo.capture()  // HEIF, RAW, Live, Depth — your call
```

That's it. Drop a `CameraPreview` view on screen and you're shooting.

---

## 📑 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Permissions](#-permissions)
- [Quick Start](#-quick-start)
- [Photo Capture](#-photo-capture)
- [Video Capture](#-video-capture)
- [Manual Controls](#-manual-controls)
- [Multi-Lens & Switching](#-multi-lens--switching)
- [Filters](#-filters-core-image)
- [Preview Views](#-preview-views)
- [Architecture](#-architecture)
- [Sample App](#-sample-app)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🚀 Features

| Category | What's inside |
| --- | --- |
| **📷 Photo** | HEIF · JPEG · RAW · RAW + HEIF · Live Photos · Depth data · Portrait effects matte · High-res stills · Quality prioritization |
| **🎥 Video** | H.264 · HEVC · ProRes 422 (LT/HQ/Proxy) · Configurable frame rate · Stabilization (standard / cinematic / cinematic-extended / auto) |
| **🎚 Manual mode** | Focus mode + manual lens position · Exposure mode + custom duration & ISO · Exposure bias · White balance mode + custom gains (temp/tint) · Smooth AF · Low-light boost · Video HDR |
| **🔍 Zoom** | Instant or ramped (with rate) · Multi-lens (ultra-wide, wide, telephoto, dual, dual-wide, triple, TrueDepth) |
| **💡 Flash & Torch** | Auto / on / off · Torch level (0–1) |
| **🎨 Filters** | Pluggable Core Image pipeline · 12 built-ins (Mono, Noir, Chrome, Fade, Instant, Process, Tonal, Transfer, Sepia, Invert, Vibrance, Posterize) · Custom `CameraFilter` protocol |
| **👁 Preview** | UIKit `AVCaptureVideoPreviewLayer` · SwiftUI wrapper with tap-to-focus & pinch-to-zoom · Metal-backed filtered preview |
| **🔐 Permissions** | Camera · Microphone · Photo library — all `async/await` |
| **🧩 API** | Modern Swift: `async/await`, `Sendable`-friendly, namespaced (`session.photo`, `session.video`, `session.controls`, `session.filters`) |

---

## 📦 Installation

### Swift Package Manager

In `Package.swift`:

```swift
.package(url: "https://github.com/iamsagb/OpenCamera", from: "0.1.0")
```

Or in Xcode: **File → Add Packages…** and paste `https://github.com/iamsagb/OpenCamera`.

### Requirements

| | Minimum |
| --- | --- |
| iOS | **15.0** |
| Swift | **5.10** |
| Xcode | **15** |

---

## 🔐 Permissions

Add the following keys to your app target's `Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>We use the camera to capture photos and videos.</string>
<key>NSMicrophoneUsageDescription</key>
<string>We use the microphone to record audio with video.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>We save captured photos and videos to your library.</string>
```

OpenCamera handles the prompts:

```swift
try await CameraPermissions.ensureCameraAccess()
try await CameraPermissions.ensureMicrophoneAccess()
let status = await CameraPermissions.requestPhotoLibrary()
```

---

## ⚡ Quick Start

A complete SwiftUI camera in 20 lines:

```swift
import OpenCamera
import SwiftUI

struct CameraView: View {
    @State private var session = OpenCamera.makeSession(.defaultPhoto)

    var body: some View {
        CameraPreview(session: session)
            .ignoresSafeArea()
            .task {
                try? await session.prepare()
                try? await session.start()
            }
    }
}
```

---

## 📷 Photo Capture

```swift
// HEIF (default)
let photo = try await session.photo.capture()
imageView.image = photo.image

// JPEG with explicit flash
let jpeg = try await session.photo.capture(flashMode: .on, format: .jpeg)

// RAW + processed HEIF (Apple ProRAW-style pair)
let pair = try await session.photo.capture(format: .rawPlusHEIF)
let rawData = pair.rawData
let processedData = pair.imageData
```

`CapturedPhoto` exposes everything AVFoundation gives you:

| Property | Type | Notes |
| --- | --- | --- |
| `image` | `UIImage?` | Convenience-decoded `imageData` |
| `imageData` | `Data?` | Processed (HEIF/JPEG) |
| `rawData` | `Data?` | DNG when RAW requested |
| `livePhotoMovieURL` | `URL?` | Paired video for Live Photos |
| `depthData` | `AVDepthData?` | When depth delivery enabled |
| `portraitEffectsMatte` | `AVPortraitEffectsMatte?` | When matte delivery enabled |
| `metadata` | `[String: Any]` | EXIF / TIFF / GPS |
| `dimensions` | `CGSize?` | Pixel size |

### Live Photos / Depth / Portrait

Enable in the configuration and OpenCamera attaches the right resources to every capture:

```swift
try await session.updateConfiguration { config in
    config.enableLivePhotos = true
    config.enableDepthData = true
    config.enablePortraitEffectsMatte = true
}
```

---

## 🎥 Video Capture

```swift
try await session.setMode(.video)

let outputURL = try await session.video.startRecording()
// …user records…
let recorded = try await session.video.stopRecording()

print(recorded.url, recorded.duration, recorded.resolution ?? .zero)
```

Codec, frame rate, and stabilization travel through the configuration:

```swift
try await session.updateConfiguration { config in
    config.videoCodec = .hevc            // .h264, .proRes422, .proRes422HQ, ...
    config.preferredFrameRate = 60
    config.stabilization = .cinematicExtended
    config.sessionPreset = .hd4K3840x2160
}
```

---

## 🎚 Manual Controls

Everything `AVCaptureDevice` exposes — typed, validated, clamped.

```swift
// Focus
try session.controls.setFocusMode(.continuousAutoFocus)
try session.controls.focus(at: devicePoint, mode: .autoFocus)
try session.controls.setLensPosition(0.42)              // 0…1, manual lens

// Exposure
try session.controls.setExposureMode(.custom)
try session.controls.setExposure(
    duration: CMTimeMake(value: 1, timescale: 60),       // 1/60s shutter
    iso: 200                                              // clamped to active format
)
try session.controls.setExposureTargetBias(-1.0)        // EV bias

// White balance
try session.controls.setWhiteBalanceMode(.locked)
try session.controls.setWhiteBalanceGains(
    .init(temperature: 5500, tint: 0)
)

// Zoom (instant or ramped)
try session.controls.setZoom(2.0)
try session.controls.setZoom(5.0, ramp: true, rate: 1.5)

// Flash & torch
session.controls.setFlashMode(.auto)
try session.controls.setTorchMode(.level(0.6))           // 0…1

// Niceties
try session.controls.setLowLightBoost(true)
try session.controls.setHDREnabled(true)
try session.controls.setSmoothAutoFocusEnabled(true)
```

Live device limits are exposed for building UI sliders:

```swift
let minISO  = session.controls.minISO
let maxISO  = session.controls.maxISO
let maxBias = session.controls.maxExposureTargetBias
let maxZoom = session.controls.maxAvailableVideoZoomFactor
```

---

## 🔄 Multi-Lens & Switching

```swift
// Toggle front ↔ back
try await session.switchCamera()

// Pick a specific lens
try await session.setPosition(.back, lens: .telephoto)

// Discover what's actually on this device
let lenses = DeviceDiscovery.availableLenses(position: .back)
// → [.ultraWide, .wide, .telephoto] on a Pro
```

Supported lenses: `.wide`, `.ultraWide`, `.telephoto`, `.dual`, `.dualWide`, `.triple`, `.trueDepth`.

---

## 🎨 Filters (Core Image)

Built-ins:

```swift
session.filters.isEnabled = true
session.filters.setFilter(BuiltInFilters.noir)
```

`BuiltInFilters.all` includes: **None · Mono · Noir · Chrome · Fade · Instant · Process · Tonal · Transfer · Sepia · Invert · Vibrance · Posterize**.

Custom filter — implement `CameraFilter`:

```swift
struct WarmFilter: CameraFilter {
    let name = "Warm"
    func apply(to image: CIImage) -> CIImage {
        image.applyingFilter("CITemperatureAndTint", parameters: [
            "inputTargetNeutral": CIVector(x: 5500, y: 0)
        ])
    }
}
session.filters.setFilter(WarmFilter())
```

Subscribe to filtered frames yourself:

```swift
session.filters.setHandler { ciImage in
    // do anything — render to a texture, ML inference, save a PNG…
}
```

---

## 👁 Preview Views

### Standard preview (SwiftUI)

```swift
CameraPreview(
    session: session,
    videoGravity: .resizeAspectFill,
    onTapToFocus: { devicePoint in
        try? session.controls.focus(at: devicePoint)
        try? session.controls.expose(at: devicePoint)
    },
    onPinchZoom: { scale in
        let next = max(1, min(session.controls.maxAvailableVideoZoomFactor ?? 5,
                              currentZoom * scale))
        try? session.controls.setZoom(next)
    }
)
```

### Filtered preview (Metal-backed)

```swift
session.filters.isEnabled = true
session.filters.setFilter(BuiltInFilters.chrome)

FilteredCameraPreview(session: session)
    .ignoresSafeArea()
```

### Plain UIKit

```swift
let preview = CameraPreviewView(session: session)
preview.videoGravity = .resizeAspectFill
view.addSubview(preview)
```

---

## 🧱 Architecture

```
OpenCamera
└── CameraSession              ← AVCaptureSession lifecycle & configuration
    ├── photo                  → PhotoCapture     (HEIF / JPEG / RAW / Live / Depth / Portrait)
    ├── video                  → VideoCapture     (codec / FPS / stabilization / recording)
    ├── controls               → ManualControls   (focus / exposure / WB / zoom / torch)
    └── filters                → FilterPipeline   (live Core Image processing)
```

Everything is composed off a single `CameraSession`. Sub-systems are namespaced so the API stays discoverable in autocomplete: `session.photo.capture(...)`, `session.controls.setZoom(...)`, etc.

### Module map

| Folder | Responsibility |
| --- | --- |
| `Core/` | `CameraConfiguration`, `CameraTypes`, `CameraError`, `CameraPermissions` |
| `Session/` | `CameraSession`, `DeviceDiscovery` |
| `Capture/` | `PhotoCapture`, `VideoCapture` |
| `Controls/` | `ManualControls` |
| `Filters/` | `CameraFilter` protocol, `BuiltInFilters`, `FilterPipeline` |
| `Preview/` | `CameraPreviewView` (UIKit), `CameraPreview` (SwiftUI), `FilteredPreviewView` / `FilteredCameraPreview` |

---

## 📱 Sample App

A full-featured SwiftUI sample lives in [`Example/`](Example/) — just open and run:

```bash
open Example/OpenCameraSample.xcodeproj
```

The sample exercises every part of the SDK:

- 📸 Photo / 🎥 Video mode toggle
- 🔄 Lens picker (`.5x` / `1x` / `3x` / multi-cam)
- 💡 Flash + torch
- 🎯 Tap-to-focus, pinch-to-zoom
- 🎚 Manual panel — ISO, shutter, WB temp/tint, EV bias
- 🎨 Filter strip (live Core Image)
- 💾 Auto-save to Photos library

> The camera is unavailable in the iOS Simulator — run on a real device.
> The project is generated by [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `Example/project.yml`; see [`Example/README.md`](Example/README.md) to regenerate.

---

## 🗺 Roadmap

- [ ] Multi-cam capture (`AVCaptureMultiCamSession`)
- [ ] Slow-mo / time-lapse helpers
- [ ] LUT / 3D-LUT filter loader
- [ ] Apple Log video pipeline
- [ ] Cinematic mode capture (iPhone 13+)
- [ ] Bracketed photo capture
- [ ] Audio configuration (channels, bit-depth)
- [ ] Visual identity tests / snapshot tests on simulator

Open an issue if you'd like one of these prioritized — or send a PR.

---

## 🤝 Contributing

PRs and issues welcome. For larger changes, please open a discussion first.

1. Fork & branch (`git checkout -b feature/your-thing`)
2. Build for iOS Simulator: `xcodebuild -scheme OpenCamera -destination 'generic/platform=iOS Simulator'`
3. Add tests where reasonable
4. Open a PR

---

## 📄 License

OpenCamera is available under the **MIT license** — see [LICENSE](LICENSE).

---

<div align="center">

Made with ☕ by **[Sagar Bhosale](mailto:bsagar242@icloud.com)**

If OpenCamera helps your project, ⭐ the repo — it's the cheapest thank-you you can give.

</div>
