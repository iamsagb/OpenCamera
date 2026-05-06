# OpenCamera Sample App

A SwiftUI sample app demonstrating the full OpenCamera SDK:

- 📸 Photo (HEIF/JPEG/RAW) and 🎥 video capture
- 🔄 Front/back/multi-lens switching with on-screen lens picker
- 🎯 Tap-to-focus, pinch-to-zoom
- 💡 Flash + torch
- 🎚 Manual mode: ISO, shutter, white balance temp/tint, EV bias
- 🎨 Live filter pipeline (Core Image)
- 💾 Auto-save to Photos library

## Run it

```bash
open Example/OpenCameraSample.xcodeproj
```

Then **set a development team** in *Signing & Capabilities*, pick a real device, and ⌘R.

> ⚠️ The camera doesn't work in the iOS Simulator — run on a physical device.

## Regenerating the Xcode project

The project is generated with [XcodeGen](https://github.com/yonaskolb/XcodeGen) from `project.yml`. To regenerate after editing the spec:

```bash
brew install xcodegen        # one time
cd Example && xcodegen generate
```

## Files

```
Example/
├── project.yml                          ← XcodeGen spec
├── OpenCameraSample.xcodeproj/          ← generated
└── OpenCameraSample/
    ├── OpenCameraSampleApp.swift        App entry point
    ├── RootView.swift                   Permission / preparation gate
    ├── CameraScreen.swift               Main camera UI
    ├── CameraViewModel.swift            Glue between SwiftUI and CameraSession
    ├── ManualControlsView.swift         Manual exposure / WB sliders
    ├── FilterPickerView.swift           Horizontal filter strip
    ├── Info.plist                       Usage descriptions + app config
    └── Assets.xcassets/                 AppIcon + AccentColor
```
