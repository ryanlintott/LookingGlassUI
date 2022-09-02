//
//  SwiftUIView.swift
//  
//
//  Created by Ryan Lintott on 2021-05-14.
//

import CoreMotion
import SwiftUI

/// How a view will appear based on device rotation
public enum DeviceRotationEffectType: String, RawRepresentable, CaseIterable, Hashable, Equatable, Identifiable {
    
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

public struct DeviceRotationEffectViewModifier: ViewModifier {
    @EnvironmentObject var motionManager: MotionManager

    let distance: CGFloat
    let perspective: CGFloat
    let offsetRotation: Quat
    let isShowingInFourDirections: Bool
    
    public init(
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
    
    let maxDimension = max(MotionManager.screenSize.height, MotionManager.screenSize.width)

    // rotation that moves to the content to the closest xy axis to the one the phone is pointing at
    // device reference frame
    var cloneRotation: Quat {
        guard isShowingInFourDirections else {
            return .identity
        }
        
        // start with a vector pointing straight down
        let originVector = Vec3(x: 0, y: 0, z: -1)
        
        // rotate the vector by the device orientation to see where the bottom of the device is pointing
        let rotatedVector = motionManager.quaternion.rotating(originVector)

        // check if the device is pointing more towards the x or y axis
        if abs(rotatedVector.x) > abs(rotatedVector.y) {
            // check which way it's pointing on the x axis and provide the appropriate rotation
            if rotatedVector.x >= 0 {
                // rotate -90 degrees
                return Quat(angle: .radians(-.pi / 2), axis: .zAxis)
            } else {
                // rotate 90 degrees
                return Quat(angle: .radians(.pi / 2), axis: .zAxis)
            }
        } else {
            // check which way it's pointing on the y axis and provide the appropriate rotation
            if rotatedVector.y >= 0 {
                // rotate 0 degrees
                return .identity
            } else {
                // rotate 180 degrees
                return Quat(angle: .radians(.pi), axis: .zAxis)
            }
        }
    }
    
    var rotation: Quat {
        /// all rotations are provided in the device reference frame
        /// Rotations occur in reverse order
        /// 1. Reference frame is changed from screen to device (x and z flip)
        /// 2. provided view is rotated according to provided offset
        /// 3. result is rotated by cloneRotation to put it in front of the viewer if they face 0, -90, 90, or 180 degrees
        /// 4. result is rotated by the inverse of the device rotation to bring it to zero
        /// 5. result is rotated by the inverse of the interface rotation to counteract any interface orientation changes
        (motionManager.interfaceRotation.inverse * motionManager.animatedQuaternion.inverse * cloneRotation * offsetRotation).deviceToScreenReferenceFrame
    }
    
    public func body(content: Content) -> some View {
        if motionManager.isDetectingMotion {
            content
                .rotation3dEffect(quaternion: rotation, anchor: .center, anchorZ: distance, perspective: perspective)
        }
    }
}

public extension View {
    /// Position a view on a sphere centered on the device and rotated using real world coordinates. This view will rotate to compensate for device rotation and appear to be seen either through a window or as a kind of reflection.
    /// - Parameters:
    ///   - type: Device rotation effect
    ///   - distance: Distance the view is positioned from the device in points
    ///   - perspective: Amount of perspective used in the view projection. (Use zero for orthographic projection where the view will not decrease in size based on distance)
    ///   - offsetRotation: Quaternion that represents the view's position on the sphere. (zero positions the view on the ground)
    ///   - isShowingInFourDirections: If active the view will be copied and rotated around the Z axis so there are 4 copies. This is helpful in ensuring a view is seen even when a device is turned to the left or right and loses sight of the original.
    /// - Returns: The view is positioned centered on the device and rotated using real world coordinates. It will rotate to compensate for device rotation and appear to be seen either through a window or as a kind of reflection.
    func deviceRotationEffect(_ type: DeviceRotationEffectType, distance: CGFloat? = nil, perspective: CGFloat? = nil, offsetRotation: Quat? = nil, isShowingInFourDirections: Bool? = nil) -> some View {
        self.modifier(DeviceRotationEffectViewModifier(type: type, distance: distance, perspective: perspective, offsetRotation: offsetRotation, isShowingInFourDirections: isShowingInFourDirections))
    }
    
    /// Position a view on a sphere centered on the device and rotated using real world coordinates. This view will rotate to compensate for device rotation and appear to be seen either through a window or as a kind of reflection.
    /// - Parameters:
    ///   - type: Device rotation effect
    ///   - distance: Distance the view is positioned from the device in points
    ///   - perspective: Amount of perspective used in the view projection. (Use zero for orthographic projection where the view will not decrease in size based on distance)
    ///   - pitch: Pitch rotation of the view (zero = on the ground, 90 degrees = in front, 180 degrees = on the ceiling)
    ///   - yaw: Yaw rotation of the view occurs after pitch (zero = in front, 90 degrees = left, -90 degrees = right, 180 degrees = behind)
    ///   - localRoll: Local roll rotation occurs after yaw and pitch and will spin the view without moving it on the sphere.
    ///   - isShowingInFourDirections: If active the view will be copied and rotated around the Z axis so there are 4 copies. This is helpful in ensuring a view is seen even when a device is turned to the left or right and loses sight of the original.
    /// - Returns: The view is positioned centered on the device and rotated using real world coordinates. It will rotate to compensate for device rotation and appear to be seen either through a window or as a kind of reflection.
    func deviceRotationEffect(_ type: DeviceRotationEffectType, distance: CGFloat? = nil, perspective: CGFloat? = nil, pitch: Angle? = nil, yaw: Angle? = nil, localRoll: Angle? = nil, isShowingInFourDirections: Bool? = nil) -> some View {
        self.deviceRotationEffect(type, distance: distance, perspective: perspective, offsetRotation: Quat(pitch: pitch, yaw: yaw, localRoll: localRoll), isShowingInFourDirections: isShowingInFourDirections)
    }
    
}
