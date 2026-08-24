# Changelog

## 0.5.0 - Unreleased

Changes since the previous versioned release, `0.4.2`.

This release raises the package's minimum platform and tools version, and reorganizes the repository so the example app's Xcode workspace no longer interferes with building the package on its own.

### Breaking Changes

- Raised the minimum supported platform from iOS 14 to iOS 15.
- Updated the package to Swift tools version 6.0 and removed the explicit `swiftLanguageVersions` setting.

### Changes

- Moved the shared Xcode workspace into `Example/` so the repository root remains a plain SwiftPM package. Previously, the root `.xcworkspace` was picked up by `xcodebuild` ahead of the package, and its local package reference only resolved by coincidence of the checkout's folder name.
- Added `.spi.yml` so Swift Package Index builds documentation for the package.
- Added a DocC catalog with a `LookingGlassUI` landing page that curates every public symbol into topic groups, matching the documentation in `FrameUp` and `ShapeUp`.
- Added a documentation badge and a Documentation section to the README linking to the API documentation on the Swift Package Index.
- Fixed README references to `.rotation3dEffect()` that should have been `.rotation3DEffect()`.
- Added `MotionManager.isPrintingViewChanges` to print the reason each LookingGlassUI view updates, preceded by a numbered marker for each motion update so view updates can be attributed to the motion update that caused them. Has no effect outside debug builds.
- Improved shimmer performance by moving the smoothing animation from a global `withAnimation` in `MotionManager` to a scoped `.animation(_:value:)` in `DeviceRotationEffectViewModifier`. Assigning `quaternion` and `animatedQuaternion` in separate transactions made SwiftUI run two full update passes per motion update. Measured on an iPhone SE running iOS 15.8.5 with five shimmer effects on screen, this halved view body evaluations from 38 to 19 per motion update. `quaternion` still delivers unanimated updates, and motion updates no longer animate unrelated state changes elsewhere in the app.
- Improved shimmer performance by calculating the four-direction clone rotation used by `isShowingInFourDirections` once per motion update in `MotionManager` instead of once per view. The value is identical for every view and only changes when the device crosses a 45 degree boundary.
