# Changelog

## 0.5.0 - Unreleased

Changes since the previous versioned release, `0.4.2`.

This release raises the package's minimum platform and tools version, reorganizes the repository so the example app's Xcode workspace no longer interferes with building the package on its own, and substantially reduces the work shimmer effects do on every motion update.

### Breaking Changes

- Raised the minimum supported platform from iOS 14 to iOS 15.
- Updated the package to Swift tools version 6.0 and removed the explicit `swiftLanguageVersions` setting.
- Moved `quaternion`, `initialDeviceRotation`, and `deltaRotation` from `MotionManager` to the new `DeviceRotation` object. Read them from `motionManager.deviceRotation`, or add `@EnvironmentObject var deviceRotation: DeviceRotation` to a view below the `motionManager` view modifier. The old properties are marked unavailable with a message pointing at the replacement.
- Removed `animatedQuaternion`. It held the same value as `quaternion` and only differed in being assigned inside a SwiftUI animation. Now that smoothing is applied by the view rather than the manager, the two would be identical. Use `DeviceRotation.quaternion` and apply `.animation(_:value:)` where the value is displayed if you need to smooth between motion updates.
- `shimmer(mode:color:background:)` and `shimmer(isOn:color:background:)` now keep showing their background colour whenever motion updates are not running, matching `ShimmerView`. Previously the background stayed painted when `MotionManager` was disabled but disappeared when the update interval was zero.

### Changes

- Improved shimmer performance substantially. `MotionManager` published the device rotation alongside its configuration, so `ObservableObject` re-evaluated every observing view on every motion update even when that view read nothing that had changed, and assigning the rotation in two separate transactions doubled that again. The rotation now lives in a separate `DeviceRotation` object observed only by the views that need it, smoothing between updates is applied by the view that displays it instead of by a global `withAnimation` in the manager, and the four-direction clone rotation used by `isShowingInFourDirections` is calculated once per motion update rather than once per view. Measured on an iPhone SE running iOS 15.8.5 with five shimmer effects in the view hierarchy, view body evaluations dropped from 38 to 5 per motion update.
- Motion updates no longer animate unrelated state changes elsewhere in the app. Smoothing was previously applied with a global `withAnimation`, which set an animation on every state change that happened in the same run loop turn.
- Fixed the `shimmer` view modifier and `ShimmerView` ignoring `disabled`. They checked only whether the update interval was above zero, so with `disabled` set the mask and blend were still composited every frame over an effect that could never appear. The blend mode versions of `shimmer` now draw nothing at all in that case.
- Added `MotionManager.isPrintingViewChanges` to print the reason each LookingGlassUI view updates, preceded by a numbered marker for each motion update so view updates can be attributed to the motion update that caused them. Has no effect outside debug builds.
- Moved the shared Xcode workspace into `Example/` so the repository root remains a plain SwiftPM package. Previously, the root `.xcworkspace` was picked up by `xcodebuild` ahead of the package, and its local package reference only resolved by coincidence of the checkout's folder name.
- Added `.spi.yml` so Swift Package Index builds documentation for the package.
- Added a DocC catalog with a `LookingGlassUI` landing page that curates every public symbol into topic groups, matching the documentation in `FrameUp` and `ShapeUp`.
- Added a documentation badge and a Documentation section to the README linking to the API documentation on the Swift Package Index.
- Fixed README references to `.rotation3dEffect()` that should have been `.rotation3DEffect()`.
