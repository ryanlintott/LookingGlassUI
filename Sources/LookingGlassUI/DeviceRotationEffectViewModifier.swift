//
//  SwiftUIView.swift
//  
//
//  Created by Ryan Lintott on 2021-05-14.
//

import CoreMotion
import FirebladeMath
import SwiftUI

public enum DeviceRotationEffectType {
    case window, reflection
}

@available(iOS 14, *)
public struct DeviceRotationEffectViewModifier: ViewModifier {
    @EnvironmentObject var motionManager: MotionManager

    let distance: CGFloat
    let perspective: CGFloat
    let offsetRotation: Quat4f
    let isShowingInFourDirections: Bool
    
    public init(
        type: DeviceRotationEffectType,
        distance: CGFloat? = nil,
        perspective: CGFloat? = nil,
        offsetRotation: Quat4f? = nil,
        isShowingInFourDirections: Bool? = nil
    ) {
        self.distance = (distance ?? 0) * (type == .window ? 1 : -1)
        self.perspective = perspective ?? 0
        self.offsetRotation = offsetRotation ?? .identity
        self.isShowingInFourDirections = isShowingInFourDirections ?? false
    }
    
    let maxDimension = max(MotionManager.screenSize.height, MotionManager.screenSize.width)
    
    // quaternion representing the interface rotation based on the deviceOrientation with some double-checking
    // note that the interface rotates in the opposite direction to the device to compensate
    // device reference frame
    var interfaceRotation: Quat4f {
        switch motionManager.deviceOrientation {
        // top of device to the left
        case .landscapeLeft:
            return Quat4f(angle: -.pi / 2, axis: .axisZ)
        // top of device to the right
        case .landscapeRight:
            return Quat4f(angle: .pi / 2, axis: .axisZ)
        case .portraitUpsideDown:
            return Quat4f(angle: .pi, axis: .axisZ)
        default:
            return .identity
        }
    }

    // rotation that moves to the content to the closest xy axis to the one the phone is pointing at
    // device reference frame
    var cloneRotation: Quat4f {
        guard isShowingInFourDirections else {
            return .identity
        }
        
        // start with a vector pointing straight down
        let originVector = Vec3f(x: 0, y: 0, z: -1)
        
        // rotate the vector by the device orientation to see where the bottom of the device is pointing
        let rotatedVector = motionManager.quaternion * originVector

        // check if the device is pointing more towards the x or y axis
        if rotatedVector.x.magnitude > rotatedVector.y.magnitude {
            // check which way it's pointing on the x axis and provide the appropriate rotation
            if rotatedVector.x >= 0 {
                // rotate -90 degrees
                return Quat4f(angle: -.pi / 2, axis: .axisZ)
            } else {
                // rotate 90 degrees
                return Quat4f(angle: .pi / 2, axis: .axisZ)
            }
        } else {
            // check which way it's pointing on the y axis and provide the appropriate rotation
            if rotatedVector.y >= 0 {
                // rotate 0 degrees
                return .identity
            } else {
                // rotate 180 degrees
                return Quat4f(angle: .pi, axis: .axisZ)
            }
        }
    }
    
    var rotation: Quat4f {
        /// all rotations are provided in the device reference frame
        /// Rotations occur in reverse order
        /// 1. Reference frame is changed from screen to device (x and z flip)
        /// 2. provided view is rotated according to provided offset
        /// 3. result is rotated by cloneRotation to put it in front of the viewer if they face 0, -90, 90, or 180 degrees
        /// 4. result is rotated by the inverse of the device rotation to bring it to zero
        /// 4. result is rotated by the inverse of the interface rotation to counteract any interface orientation changes
        (interfaceRotation.inverse * motionManager.animatedQuaternion.inverse * cloneRotation * offsetRotation).deviceToScreenReferenceFrame
    }
    
    public func body(content: Content) -> some View {
        if motionManager.isDetectingMotion {
            content
                .rotation3dEffect(quaternion: rotation, anchor: .center, anchorZ: distance, perspective: perspective)
        }
    }
}

@available (iOS 14, *)
public extension View {
    func deviceRotationEffect(_ type: DeviceRotationEffectType, distance: CGFloat? = nil, perspective: CGFloat? = nil, offsetRotation: Quat4f? = nil, isShowingInFourDirections: Bool? = nil) -> some View {
        self.modifier(DeviceRotationEffectViewModifier(type: type, distance: distance, perspective: perspective, offsetRotation: offsetRotation, isShowingInFourDirections: isShowingInFourDirections))
    }
    
    
    func deviceRotationEffect(_ type: DeviceRotationEffectType, distance: CGFloat? = nil, perspective: CGFloat? = nil, pitch: Angle? = nil, yaw: Angle? = nil, localRoll: Angle? = nil, isShowingInFourDirections: Bool? = nil) -> some View {
        self.deviceRotationEffect(type, distance: distance, perspective: perspective, offsetRotation: Quat4f(pitch: pitch, yaw: yaw, localRoll: localRoll), isShowingInFourDirections: isShowingInFourDirections)
    }
    
}
