# LookingGlassUI
![License](https://img.shields.io/github/license/ryanlintott/LookingGlassUI)
![Version](https://img.shields.io/github/v/tag/ryanlintott/LookingGlassUI?label=version)

A 3d rotation effect that uses Core Motion to allow SwiftUI views to appear projected in a specific direction and distance relative to the device in real world space.

## Shimmer

This rotation effect is especially useful in faking a light reflection to create a shimmering effect when the device rotates. The package includes a default shimmer effect.

## Demo
This package is currently used to create a gold shimmer effect on many gold elements in the [Old English Wordhord app](https://oldenglishwordhord.com/app). Download it to see the effect in action.

<a href="https://apps.apple.com/us/app/old-english-wordhord/id1535982564?itsct=apps_box_badge&amp;itscg=30200" style="display: inline-block; overflow: hidden; border-top-left-radius: 13px; border-top-right-radius: 13px; border-bottom-right-radius: 13px; border-bottom-left-radius: 13px; width: 250px; height: 83px;">
<img alt="Wordhord App with shimmering gold elmenets" src="https://oldenglishwordhord.files.wordpress.com/2021/07/goldshimmerclip-v002.gif" width="20%" height="20%"/>

<img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1626912000&h=8e86ea0b88a4e8559b76592c43b3fe60" alt="Download on the App Store" style="border-top-left-radius: 13px; border-top-right-radius: 13px; border-bottom-right-radius: 13px; border-bottom-left-radius: 13px; width: 250px; height: 83px;"></a>

## Example App
Check out [LookingGlassUIExample](https://github.com/ryanlintott/LookingGlassUIExample) to see how to use this package in an iOS app.

## Installation

1. In XCode 12 go to `File -> Swift Packages -> Add Package Dependency` or in XCode 13 `File -> Add Packages`
2. Paste in the repo's url: `https://github.com/ryanlintott/LookingGlassUI` and select main branch or select by version.

## Usage

Import the package using `import LookingGlassUI`

### MotionManager
Before adding any custom views, add the `.motionManager` view modifier once, somewhere in the heirarchy above any other views or modifiers used in this package.
```swift
ContentView()
    .motionManager(updateInterval: 0.1, disabled: false)
```

### ShimmerView
Use `ShimmerView` if you want a view that acts like `Color` but with a default shimmer effect. If `MotionManager` is disabled only the background color will be shown.
```swift
ShimmerView(color: .goldShimmer, background: .gold)
```

### .shimmer()
Use `.shimmer()` view modifier if you want to add a default shimmer effect to another SwiftUI View. If `MotionManager` is disabled the modifier has no effect.
```swift
Text("Hello, World!")
    .shimmer(color: .gold)
```

### LookingGlass
Use `LookingGlass` if you want to project any SwiftUI view or create your own custom effect.  Content appears as if rotated and positioned from the center of the device regardless of positioin on the screen or if it's in a scrollview. If `MotionManager` is disabled nothing will be shown.
```swift
LookingGlass(.reflection, distance: 4000, perspective: 0, pitch: .degrees(45), yaw: .zero, localRoll: .zero, isShowingInFourDirections: false) {
    Text("Hello, World")
        .foregroundColor(.white)
        .frame(width: 500, height: 500)
        .background(Color.red)
}
```

### .deviceRotationEffect()
Use `.deviceRotationEffect()` if you want to rotate a view based on device rotation. Content is rotated and positioned based on it's own center. If `MotionManager` is disabled nothing will be shown.
```swift
Text("Hello, World")
    .foregroundColor(.white)
    .frame(width: 500, height: 500)
    .background(Color.red)
    .deviceRotationEffect(.reflection, distance: 4000, perspective: 0, pitch: .degrees(10), yaw: .zero, localRoll: .zero, isShowingInFourDirections: false)
```

## Window and Reflection Modes

In window mode a view appears as if your phone is a window looking into a 3d environment.

In reflection mode a view appears as if your phone has a camera pointing out of the screen back at a 3d envrionment. It's not a true reflection as it doesn't take into account the viewer's eye location but it's a useful approximation.

## Positioning Views

Views are positioned based on a quaternion or simple pitch, yaw, and local roll angles.
All angles at zero means the view will be visible when the phone is flat with the top pointing away from the user.
Pitch of 90 degrees will bring the view up directly in front of the user.
Yaw will move the view to the left or right.
Local Roll will spin the view in place.

## Dependencies

[Fireblade Math](https://github.com/fireblade-engine/math)
