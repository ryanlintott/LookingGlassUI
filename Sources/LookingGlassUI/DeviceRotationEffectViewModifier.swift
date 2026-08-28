//
//  DeviceRotationEffectViewModifier.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2021-05-14.
//

import CoreMotion
import SwiftUI

/// How a view will appear based on device rotation
public enum DeviceRotationEffectType: String, RawRepresentable, CaseIterable, Hashable, Equatable, Identifiable, Sendable {
    
    /// Device acts as a window showing whatever views are positioned behind the screen.
    ///
    /// Content views can be rotated and positioned on a sphere centered on the device and can only be seen if the back of the device is pointing at them.
    case window
    
    /// Device acts as a mirror showing whatever views are positioned in front of the screen.
    ///
    /// Content views can be rotated and positioned on a sphere centered on the device and can only be seen if the front of the device is pointing at them.
    case reflection
    
    public var id: Self { self }
}

struct DeviceRotationEffectViewModifier: ViewModifier {
    /// Taken from the environment, so this effect reads the configuration of the scene containing it. Like every other effect in this package it requires a ``SwiftUICore/View/motionManager(updateInterval:disabled:)`` modifier above it and traps without one.
    @EnvironmentObject private var motionManager: MotionManager
    @EnvironmentObject private var deviceMotion: DeviceMotion

    let distance: CGFloat
    let perspective: CGFloat
    let offsetRotation: Quat
    let isShowingInFourDirections: Bool
    
    init(
        type: DeviceRotationEffectType,
        distance: CGFloat? = nil,
        perspective: CGFloat? = nil,
        offsetRotation: Quat? = nil,
        isShowingInFourDirections: Bool? = nil
    ) {
        self.distance = (distance ?? 0) * (type == .window ? 1 : -1)
        self.perspective = perspective ?? 0
        self.offsetRotation = offsetRotation ?? .identity
        self.isShowingInFourDirections = isShowingInFourDirections ?? false
    }

    var rotation: Quat {
        deviceMotion.realWorldOrientation(offset: offsetRotation, isShowingInFourDirections: isShowingInFourDirections)
    }
    
    /// Animation that smooths movement between motion updates.
    ///
    /// No animation is used on updates where ``DeviceMotion/cloneRotation`` changes as that rotation snaps between 90 degree intervals and animating it would sweep the view around instead.
    var animation: Animation? {
        if isShowingInFourDirections && deviceMotion.cloneRotationDidChange {
            return nil
        }
        return deviceMotion.animation
    }
    
    func body(content: Content) -> some View {
        let _ = Self.printChangesIfEnabled()
        if motionManager.isDetectingMotion {
            content
                .rotation3DEffect(quaternion: rotation, anchor: .center, anchorZ: distance, perspective: perspective)
                /// Animated on the device rotation rather than on `rotation` so only device movement is smoothed. `rotation` also changes when the interface orientation changes and that 90 degree step must snap.
                .animation(animation, value: deviceMotion.quaternion)
        }
    }
}

public extension View {
    /// Position a view on a sphere centered on the device and rotated using real world coordinates. This view will rotate to compensate for device rotation and appear to be seen either through a window or as a kind of reflection.
    ///
    /// - Requires: Use the `.motionManager` view modifier above this view in the hierarchy.
    ///
    /// - Parameters:
    ///   - type: Device rotation effect.
    ///   - distance: Distance the view is positioned from the device in points.
    ///   - perspective: Amount of perspective used in the view projection. (default of zero creates an orthographic projection where the view will not decrease in size based on distance)
    ///   - offsetRotation: Quaternion that represents the view's position in the real world. (zero positions the view on the ground)
    ///   - isShowingInFourDirections: If enabled and the device turns more than 45 degrees on the z axis away from one of the x or y axis directions the view will rotate 90 degrees towards the new closest axis direction.
    /// - Returns: The view is positioned centered on the device and rotated using real world coordinates. It will rotate to compensate for device rotation and appear to be seen either through a window or as a kind of reflection.
    func deviceRotationEffect(
        _ type: DeviceRotationEffectType,
        distance: CGFloat? = nil,
        perspective: CGFloat? = nil,
        offsetRotation: Quat? = nil,
        isShowingInFourDirections: Bool? = nil
    ) -> some View {
        self.modifier(
            DeviceRotationEffectViewModifier(
                type: type,
                distance: distance,
                perspective: perspective,
                offsetRotation: offsetRotation,
                isShowingInFourDirections: isShowingInFourDirections
            )
        )
    }
    
    /// Position a view on a sphere centered on the device and rotated using real world coordinates. This view will rotate to compensate for device rotation and appear to be seen either through a window or as a kind of reflection.
    ///
    /// - Requires: Use the `.motionManager` view modifier above this view in the hierarchy.
    /// 
    /// - Parameters:
    ///   - type: Device rotation effect.
    ///   - distance: Distance the view is positioned from the device in points.
    ///   - perspective: Amount of perspective used in the view projection. (default of zero creates an orthographic projection where the view will not decrease in size based on distance)
    ///   - pitch: Pitch rotation of the view (zero = on the ground, 90 degrees = in front, 180 degrees = on the ceiling)
    ///   - yaw: Yaw rotation of the view (zero = in front, 90 degrees = left, -90 degrees = right, 180 degrees = behind)
    ///   - localRoll: Local roll rotation of the view.
    ///   - isShowingInFourDirections: If enabled and the device turns more than 45 degrees on the z axis away from one of the x or y axis directions the view will rotate 90 degrees towards the new closest axis direction.
    /// - Returns: The view is positioned centered on the device and rotated using real world coordinates. It will rotate to compensate for device rotation and appear to be seen either through a window or as a kind of reflection.
    func deviceRotationEffect(
        _ type: DeviceRotationEffectType,
        distance: CGFloat? = nil,
        perspective: CGFloat? = nil,
        pitch: Angle? = nil,
        yaw: Angle? = nil,
        localRoll: Angle? = nil,
        isShowingInFourDirections: Bool? = nil
    ) -> some View {
        deviceRotationEffect(
            type,
            distance: distance,
            perspective: perspective,
            offsetRotation: Quat(pitch: pitch,
            yaw: yaw,
            localRoll: localRoll),
            isShowingInFourDirections: isShowingInFourDirections
        )
    }
}
