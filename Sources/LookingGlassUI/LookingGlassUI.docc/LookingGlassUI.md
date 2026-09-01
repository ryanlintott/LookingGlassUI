# ``LookingGlassUI``

A Swift Package that creates shimmer, parallax, and other SwiftUI effects based on real-world device orientation.

## Overview

Add ``SwiftUICore/View/motionManager(updateInterval:disabled:)`` once near the top of each scene's view hierarchy and every other feature in this package can use device motion. It places that scene's ``MotionManager`` and the shared ``DeviceMotion`` in the environment. Every scene shares one Core Motion service, driven by the fastest interval any enabled foreground scene needs. Backgrounding, closing, or disabling one scene does not stop updates needed by another foreground scene, and a disabled scene does not display motion effects while another scene remains active.

Make a color catch the light as the device turns with ``ShimmerView``, or add that shimmer to any view with ``SwiftUICore/View/shimmer(mode:color:background:)``. Shift a view as the device tilts with ``SwiftUICore/View/parallax(distance:maxOffset:)``. Lock a view to a real-world angle with ``LookingGlass`` or ``SwiftUICore/View/deviceRotationEffect(_:distance:perspective:pitch:yaw:localRoll:isShowingInFourDirections:)`` so it appears through the screen as if seen through a window or a reflection, and is only visible when the device points at it.

```swift
ContentView()
    .motionManager(updateInterval: 0.1, disabled: false)

ShimmerView(mode: .darkModeOnly, color: .goldShimmer, background: .gold)

Text("Hello, World!")
    .shimmer(color: .gold)

Text("Hello, World!")
    .parallax(distance: 40, maxOffset: 100)

LookingGlass(.reflection, distance: 4000, perspective: 0, pitch: .degrees(45), yaw: .zero, localRoll: .zero) {
    Text("Hello, World!")
}
```

## What each effect does when motion updates are off

An effect is off when its scene passed a zero `updateInterval` or `disabled: true`. Each one falls back differently, so pick the one whose empty state suits the layout:

| Effect | With motion updates off |
| --- | --- |
| ``LookingGlass`` | Takes the same space and draws nothing |
| ``SwiftUICore/View/deviceRotationEffect(_:distance:perspective:pitch:yaw:localRoll:isShowingInFourDirections:)`` | Draws nothing and takes no space |
| ``SwiftUICore/View/parallax(distance:maxOffset:)`` | Draws the view unmoved |
| ``ShimmerView`` and ``SwiftUICore/View/shimmer(mode:color:background:)`` | Draws the background colour alone |
| ``SwiftUICore/View/shimmer(mode:color:blendMode:)`` | Draws nothing over the view |

Motion updates also stop while the app or the scene is in the background, but that does not turn effects off: they stay on screen at their last rotation, so they are still there in the app switcher snapshot.

Every effect reads its scene's configuration from the environment, so ``SwiftUICore/View/motionManager(updateInterval:disabled:)`` is required above it. Leaving the modifier out is a programmer error rather than a fifth way for an effect to be off, and traps rather than drawing one of the fallbacks above.

Rotations use ``Quat``, a wrapper around `simd_quatd` with pitch, yaw, and local roll, and ``SwiftUICore/View/rotation3DEffect(quaternion:anchor:anchorZ:perspective:)`` applies one to any view for a smooth rotation from any orientation to any other. Interface orientation changes are compensated for automatically, so views stay locked to the real world.

Requires iOS 15+.

For a feature-by-feature guide with examples, see the [README](https://github.com/ryanlintott/LookingGlassUI), and the `Example` folder in the [repository](https://github.com/ryanlintott/LookingGlassUI) for a demo app.

## Topics

### Setup

- ``SwiftUICore/View/motionManager(updateInterval:disabled:)``
- ``MotionManager``
- ``DeviceMotion``

### Shimmer

- ``ShimmerView``
- ``ShimmerMode``
- ``SwiftUICore/View/shimmer(mode:color:background:)``
- ``SwiftUICore/View/shimmer(isOn:color:background:)``
- ``SwiftUICore/View/shimmer(mode:color:blendMode:)``
- ``SwiftUICore/View/shimmer(isOn:color:blendMode:)``

### Parallax

- ``SwiftUICore/View/parallax(distance:maxOffset:)``

### Real-World Rotation

- ``LookingGlass``
- ``DeviceRotationEffectType``
- ``SwiftUICore/View/deviceRotationEffect(_:distance:perspective:pitch:yaw:localRoll:isShowingInFourDirections:)``
- ``SwiftUICore/View/deviceRotationEffect(_:distance:perspective:offsetRotation:isShowingInFourDirections:)``

### Quaternions and Vectors

- ``Quat``
- ``Vec3``
- ``SwiftUICore/View/rotation3DEffect(quaternion:anchor:anchorZ:perspective:)``

### Debugging

- ``QuaternionDataView``

### Extended Types

- ``Swift/SIMD3``
