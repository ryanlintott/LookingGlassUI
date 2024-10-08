<img width="650" alt="LookingGlassUI Logo with a rectangular border in shimmering gold on black" src="https://user-images.githubusercontent.com/2143656/128274524-6aa6dc0e-b02d-408a-ad9d-9fa1e0cb06d2.gif">

[![Swift Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanlintott%2FLookingGlassUI%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/ryanlintott/LookingGlassUI)
[![Platform Compatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fryanlintott%2FLookingGlassUI%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/ryanlintott/LookingGlassUI)
![License - MIT](https://img.shields.io/github/license/ryanlintott/LookingGlassUI)
![Version](https://img.shields.io/github/v/tag/ryanlintott/LookingGlassUI?label=version)
![GitHub last commit](https://img.shields.io/github/last-commit/ryanlintott/LookingGlassUI)
[![Mastodon](https://img.shields.io/badge/mastodon-@ryanlintott-5c4ee4.svg?style=flat)](http://mastodon.social/@ryanlintott)
[![Twitter](https://img.shields.io/badge/twitter-@ryanlintott-blue.svg?style=flat)](http://twitter.com/ryanlintott)

# Overview
Create shimmer, parallax or other rotation effects based on device orientation.

- [`.motionManager()`](#motionmanager) - A view modifier that adds a `MotionManager` class into the environment.
- [`ShimmerView`](#shimmerview) - A color that shimmers with another color as if reflecting light when the device rotates.
- [`.shimmer()`](#shimmer) - A view modifier that overlays a shimmer color as if reflecting light when the device rotates.
- [`.parallax()`](#parallax) - A view modifier that moves the view to add a parallax effect when the device rotates.
- [`LookingGlass`](#lookingglass) - A view that rotates its child view to a specific 3d angle relative to the real world and positions it relative to the device.
- [`.deviceRotationEffect()`](#devicerotationeffect) - A view modifier that rotates a view based on device rotation.
- [`.rotation3dEffect()`](#rotation3deffect) - A view modifier that rotates a view based on a quaternion.
- [`Quat`](#quat) - A wrapper for simd.quaternion with handy extensions.

# Demo App
The `Example` folder has an app that demonstrates the features of this package.

# Installation and Usage
This package is compatible with iOS 14+.

1. In Xcode go to `File -> Add Packages`
2. Paste in the repo's url: `https://github.com/ryanlintott/LookingGlassUI` and select by version.
3. Import the package using `import LookingGlassUI`

# Is this Production-Ready?
Really it's up to you. I currently use this package to create a gold shimmer effect on many gold elements in the [Old English Wordhord app](https://oldenglishwordhord.com/app). Download it for free and turn on the shimmer effect in Settings.

![An iphone rotated back and forth showing the Old English Wordhord App with all the gold elements shimmering as if reflecting light. A screen recording on the right shows the same content.](https://user-images.githubusercontent.com/2143656/128365446-6f9edb2a-e318-44c7-b095-4ab8b9c820f5.gif)

<a href="https://apps.apple.com/us/app/old-english-wordhord/id1535982564?itsct=apps_box_badge&amp;itscg=30200">
<img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1626912000&h=8e86ea0b88a4e8559b76592c43b3fe60" alt="Download on the App Store" style="border-top-left-radius: 13px; border-top-right-radius: 13px; border-bottom-right-radius: 13px; border-bottom-left-radius: 13px; width: 250px; height: 83px;">
</a>

# Support This Project
LookingGlassUI is open source and free but if you like using it, please consider supporting my work.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/X7X04PU6T)

# Details
## .motionManager()
Before adding any custom views, add the `.motionManager` view modifier once in your app, somewhere in the heirarchy above any other views or modifiers used in this package.
```swift
ContentView()
    .motionManager(updateInterval: 0.1, disabled: false)
```

## ShimmerView
*Requires [`.motionManager()`](#motionmanager)*

This view acts like `Color` but a second shimmer color will appear when device is rotated. The effect can be enabled via a parameter or set to only show in dark or light mode. If `MotionManager` is disabled only the background color will be shown.
```swift
ShimmerView(mode: .darkModeOnly, color: .goldShimmer, background: .gold)
```

## .shimmer()
*Requires [`.motionManager()`](#motionmanager)*

Use `.shimmer()` view modifier if you want to add a default shimmer effect to another SwiftUI View. If `MotionManager` is disabled the modifier has no effect.
```swift
Text("Hello, World!")
    .shimmer(color: .gold)
```

## .parallax()
*Requires [`.motionManager()`](#motionmanager)*

Use `.parallax(multiplier: CGFloat, maxOffset: CGFloat)` view modifier if you want to add a parallax effect to any SwiftUI View. If `MotionManager` is disabled the modifier has no effect.
```swift
Text("Hello, World!")
    .parallax(multiplier: 40, maxOffset: 100)
```

## LookingGlass
*Requires [`.motionManager()`](#motionmanager)*

Use `LookingGlass` if you want to project any SwiftUI view based on a real-world rotation and create your own custom effect. Content appears as if rotated and positioned from the center of the device regardless of positioin on the screen or if it's in a scrollview. If `MotionManager` is disabled nothing will be shown.
```swift
LookingGlass(.reflection, distance: 4000, perspective: 0, pitch: .degrees(45), yaw: .zero, localRoll: .zero, isShowingInFourDirections: false) {
    Text("Hello, World")
        .foregroundColor(.white)
        .frame(width: 500, height: 500)
        .background(Color.red)
}
```

## .deviceRotationEffect()
*Requires [`.motionManager()`](#motionmanager)*

Use `.deviceRotationEffect()` if you want to rotate a view based on device rotation. Content is rotated and positioned based on it's own center. If `MotionManager` is disabled nothing will be shown.
```swift
Text("Hello, World")
    .foregroundColor(.white)
    .frame(width: 500, height: 500)
    .background(Color.red)
    .deviceRotationEffect(.reflection, distance: 4000, perspective: 0, pitch: .degrees(10), yaw: .zero, localRoll: .zero, isShowingInFourDirections: false)
```

## rotation3dEffect()
Rotate SwiftUI Views based on quaterions. This ensures a smooth rotation from any point to any other point.
```swift
Text("Hello, World")
    .rotation3dEffect(quaternion: Quat(pitch: .degrees(45), yaw: .zero, localRoll: .degrees(-30)), anchor: .center, anchorZ: 200, perspective: 0.2)
```

## Quat
`Quat` is a wrapper for simd.quaternion with handy parameters like yaw, pitch, and roll and a way to init from pitch, yaw and localRoll.

# How it Works

## Window and Reflection Modes
In window mode a view appears as if your phone is a window looking into a 3d environment.

In reflection mode a view appears as if your phone has a camera pointing out of the screen back at a 3d envrionment. It's not a true reflection as it doesn't take into account the viewer's eye location but it's a useful approximation.

## Positioning View
Views are positioned based on a quaternion or pitch, yaw, and local roll angles.
All angles at zero means the view will be visible when the phone is flat with the top pointing away from the user. (see diagram below)
1. Local Roll rotate the view around the Z axis. 10 degrees will tilt the view counter-clockwise
2. Pitch will rotate the view around the X axis. 90 degrees will bring the view up directly in front of the user.
3. Yaw will rotate the view around the Z axis again. 5 degrees will move the view slightly to the left of the user. If you set isShowingInFourDirections to true the view will be copied 3 additional times and rotated at -90, 90, and 180 degrees from the position you chose.
4. The view is then moved away from the origin based on the distance provided. The direction is dependant on choosing window or reflection.
6. As the user moves their device around they will always see your view in the location you've set.

Don't worry about device orientation. Although Core Motion doesn't compensate for this, LookingGlassUI does.

![Digram titled LookingGlassUI Rotation: View Rotation Axes shows a tall grey rectangle flat one a surface with positive Z up, positive Y to the top of the rectangle and positive X to the right. Positive Z is World Up and positive Y is the top of view at zero, the direction user was facing when app was opened. Z axis has Yaw and Local Roll rotational arrows and X axis has Pitch. All arrows follow right hand rule. Another rectangle rotated 90 degrees is on top and a note reads: Orientation changes will not change axes.](https://user-images.githubusercontent.com/2143656/128418630-85f31175-a616-49cc-b25a-4b82f1a6d0b3.png)

## Additional Rotation Diagrams
3D space is confusing on iOS, especially as Core Motion and SwiftUI's rotation3dEffect each seem to use different axes. I created this diagram to keep track of how each one works. You probably won't need these unless you want to do something more custom. It's important to note that the Screen Rotation Axes are only used for determining rotation direction using the [right hand rule for a rotating body](https://en.wikipedia.org/wiki/Right-hand_rule). When translating a view (using .offset or similar), the axes are different with +Y towards the bottom of the screen and +X to the right. These axes are not needed as we only deal with rotation

![iOS Rotation. One diagram on the left titled: Device Rotation Axes (Core Motion) shows a tall grey rectangle flat on a surface with positive Z up, positive Y to the top of the rectangle and positive X to the right. Axes have Yaw, Roll, and Pitch rotational arrows respectively, each following the right hand rule. An additional note says: Device axis do not change when orientation changes. Another diagram on the right titled: Screen Rotation Axes (SwiftUI .rotation3dEffect) shows a tall grey rectangle flat on a surface with negative Z up, positive Y to the top of the device and negative X to the right. Axes have Yaw, Roll, and Pitch rotational arrows respectively, each following the right hand rule. Another rectangle rotated 90 degrees is on top and a note reads: Screen top changes if app supports multiple orientation.](https://user-images.githubusercontent.com/2143656/152568546-00365387-9fd9-4eb7-9048-22adc92800c3.png)

