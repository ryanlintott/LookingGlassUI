# Changelog

## 0.5.0 - Unreleased

Changes since the previous versioned release, `0.4.2`.

This release raises the package's minimum platform and tools version, reorganizes the repository so the example app's Xcode workspace no longer interferes with building the package on its own, coordinates one Core Motion service across multiple scenes, and substantially reduces the work shimmer effects do on every motion update.

### Breaking Changes

- Raised the minimum supported platform from iOS 14 to iOS 15.
- Updated the package to Swift tools version 6.0 and removed the explicit `swiftLanguageVersions` setting.
- Add `.motionManager(updateInterval:disabled:)` once near the top of each scene's view hierarchy rather than once for the whole app. Each modifier now registers that scene's requested configuration with the shared `MotionManager`.
- `MotionManager.updateInterval`, `MotionManager.disabled`, and `MotionManager.isDetectingMotion` now describe the effective app-wide motion configuration rather than any one scene's requested values. The built-in effects still respect the `updateInterval` and `disabled` values supplied by their own scene.
- Moved `quaternion`, `initialDeviceRotation`, and `deltaRotation` from `MotionManager` to the new `DeviceRotation` object. Read them from `motionManager.deviceRotation`, or add `@EnvironmentObject var deviceRotation: DeviceRotation` to a view below the `motionManager` view modifier. The old properties are marked unavailable with a message pointing at the replacement.
- Removed `animatedQuaternion`. It held the same value as `quaternion` and only differed in being assigned inside a SwiftUI animation. Now that smoothing is applied by the view rather than the manager, the two would be identical. Use `DeviceRotation.quaternion` and animate it where it's displayed if you need to smooth between motion updates, matching the animation to the update interval with `.animation(motionManager.animation, value: deviceRotation.quaternion)`.
- Made `MotionManager.changeDeviceOrientation()` unavailable because the manager responds to supported device-orientation changes automatically. Remove calls to this method; no replacement is needed.
- Made `MotionManager.setUpdateInterval(_:)` unavailable. Pass the update interval to `.motionManager(updateInterval:disabled:)` instead.
- Made `MotionManager.setDisabled(_:)` unavailable. Pass the disabled state to `.motionManager(updateInterval:disabled:)` instead.
- Made `MotionManager.startMotionUpdates(updateInterval:disabled:setDeviceOrientation:)` unavailable. Configure motion updates with `.motionManager(updateInterval:disabled:)`; they start automatically.
- Made `MotionManager.restart()` unavailable. Motion updates are managed automatically when their configuration changes, the device orientation changes, or the app moves between the foreground and background.
- Made `MotionManager.stopMotionUpdates()` unavailable. Configure motion updates with `.motionManager(updateInterval:disabled:)`; they stop automatically when no enabled scene needs them or the app enters the background.
- `shimmer(mode:color:background:)` and `shimmer(isOn:color:background:)` now keep showing their background colour whenever motion updates are not running, matching `ShimmerView`. Previously the background stayed painted when `MotionManager` was disabled but disappeared when the update interval was zero.

### Changes

- Fixed multi-window apps stopping device motion when any one scene disappeared. Each scene now registers its own lifecycle-aware request with the shared `MotionManager`; the fastest enabled foreground interval controls the app's single Core Motion service, and updates stop only after no enabled foreground scene needs them. Backgrounding, closing, or disabling one scene does not stop another foreground scene's updates, and a scene disabled locally keeps its effects off while another scene is using motion updates.
- Improved shimmer performance substantially. `MotionManager` published the device rotation alongside its configuration, so `ObservableObject` re-evaluated every observing view on every motion update even when that view read nothing that had changed, and assigning the rotation in two separate transactions doubled that again. The rotation now lives in a separate `DeviceRotation` object observed only by the views that need it, smoothing between updates is applied by the view that displays it instead of by a global `withAnimation` in the manager, and the four-direction clone rotation used by `isShowingInFourDirections` is calculated once per motion update rather than once per view. Measured on an iPhone SE running iOS 15.8.5 with five shimmer effects in the view hierarchy, view body evaluations dropped from 38 to 5 per motion update.
- Added `MotionManager.animation`, a linear animation with a duration matching the update interval, for smoothing values that change with device motion.
- Motion updates no longer animate unrelated state changes elsewhere in the app. Smoothing was previously applied with a global `withAnimation`, which set an animation on every state change that happened in the same run loop turn.
- Fixed the `shimmer` view modifier and `ShimmerView` ignoring `disabled`. They checked only whether the update interval was above zero, so with `disabled` set the mask and blend were still composited every frame over an effect that could never appear. The blend mode versions of `shimmer` now draw nothing at all in that case.
- Fixed shimmer and `LookingGlass` content being sized wrong when the app was opened in landscape. The screen size was previously captured once from `UIScreen.main.bounds` and then adjusted using the device orientation. `LookingGlass` now reads the current screen bounds when it renders, so it uses the full screen dimensions in the current interface orientation directly.
- Moved the shared Xcode workspace into `Example/` so the repository root remains a plain SwiftPM package. Previously, the root `.xcworkspace` was picked up by `xcodebuild` ahead of the package, and its local package reference only resolved by coincidence of the checkout's folder name.
- Added `.spi.yml` so Swift Package Index builds documentation for the package.
- Added a DocC catalog with a `LookingGlassUI` landing page that curates every public symbol into topic groups, matching the documentation in `FrameUp` and `ShapeUp`.
- Added a documentation badge and a Documentation section to the README linking to the API documentation on the Swift Package Index.
- Replaced the Twitter badge in the README with a Bluesky badge.
- Documented that the `shimmer` view modifier draws copies of the view, so state inside the view that changes its size or shape may not be reflected in the shimmer and any `onAppear` or `task` on the view may run more than once.
- Documented `MotionManager` and `QuaternionDataView`, which had no description of their own, and added a README section on reading `MotionManager` and `DeviceRotation` directly from the environment.
- Fixed README references to `.rotation3dEffect()` that should have been `.rotation3DEffect()`.
