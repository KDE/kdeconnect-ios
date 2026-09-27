# SwiftUI-MediaPicker (vendored)

Vendored copy of [UWAppDev/SwiftUI-MediaPicker](https://github.com/UWAppDev/SwiftUI-MediaPicker)
at tag `0.2.0` (`96f18b1350873dec0a76355c7060cd0a06100901`), licensed under
the MIT License (see `LICENSE`). The upstream demo app is not included.

## Local modifications

- `Sources/MediaPicker/MediaPicker-PhotosUI.swift`: only the first
  `didFinishPicking` call per presentation is handled, and the picker stops
  accepting input after it. Before this change, tapping "Add" again while
  "Preparing Media…" was shown imported and sent the selection twice.
