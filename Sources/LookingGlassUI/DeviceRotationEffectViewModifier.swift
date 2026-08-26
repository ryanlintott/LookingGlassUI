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
    @EnvironmentObject var motionManager: MotionManager
    @EnvironmentObject var deviceRotation: DeviceRotation
    @Environment(\.motionUpdatesEnabled) private var motionUpdatesEnabled

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

    // rotation that moves to the content to the closest xy axis to the one the phone is pointing at
    // device reference frame
    var cloneRotation: Quat {
        isShowingInFourDirections ? deviceRotation.cloneRotation : .identity
    }
    
    var rotation: Quat {
        /// all rotations are provided in the device reference frame
        /// Rotations occur in reverse order
        /// 1. Reference frame is changed from screen to device (x and z flip)
        /// 2. provided view is rotated according to provided offset
        /// 3. result is rotated by cloneRotation to put it in front of the viewer if they face 0, -90, 90, or 180 degrees
        /// 4. result is rotated by the inverse of the device rotation to bring it to zero
        /// 5. result is rotated by the inverse of the interface rotation to counteract any interface orientation changes
        (motionManager.interfaceRotation.inverse * deviceRotation.quaternion.inverse * cloneRotation * offsetRotation).deviceToScreenReferenceFrame
    }
    
    /// Animation that smooths movement between motion updates.
    ///
    /// No animation is used on updates where ``DeviceRotation/cloneRotation`` changes as that rotation snaps between 90 degree intervals and animating it would sweep the view around instead.
    var animation: Animation? {
        if isShowingInFourDirections && deviceRotation.cloneRotationDidChange {
            return nil
        }
        return motionManager.animation
    }
    
    func body(content: Content) -> some View {
        let _ = Self.printChangesIfEnabled()
        if motionUpdatesEnabled {
            content
                .rotation3DEffect(quaternion: rotation, anchor: .center, anchorZ: distance, perspective: perspective)
                /// Animated on the device rotation rather than on `rotation` so only device movement is smoothed. `rotation` also changes when the interface orientation changes and that 90 degree step must snap.
                .animation(animation, value: deviceRotation.quaternion)
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
    ///   - isShowingInFourDirections: If active the view will be rotated around the Z axis at 90 degree intervals to always face the direction the device is pointing.
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
    ///   - isShowingInFourDirections: If active the view will be rotated around the Z axis at 90 degree intervals to always face the direction the device is pointing.
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
