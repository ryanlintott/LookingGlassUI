//
//  DeviceRotation.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-24.
//

import SwiftUI

/// The rotation of the device, updated on every motion update.
///
/// Access this via ``MotionManager/deviceRotation`` or from the environment. ``SwiftUICore/View/motionManager(updateInterval:disabled:)`` places it there alongside ``MotionManager``.
///
/// ```swift
/// @EnvironmentObject var deviceRotation: DeviceRotation
/// ```
///
/// These values are kept separate from ``MotionManager`` because they change many times a second. `ObservableObject` invalidates every observing view whenever any published property changes, so a view that reads only configuration would be re-evaluated on every motion update if these lived on the manager.
@MainActor
public final class DeviceRotation: ObservableObject {
    init() { }
    
    /// Rotation of device relative to zero position.
    ///
    /// This value steps once per motion update with no smoothing. Views that need smooth movement between updates animate it themselves, as `.deviceRotationEffect()` does:
    ///
    /// ```swift
    /// .animation(.linear(duration: motionManager.updateInterval), value: deviceRotation.quaternion)
    /// ```
    @Published public private(set) var quaternion: Quat = .identity
    
    /// Rotation from zero to initial position of device when motion updates started.
    ///
    /// This value is reset whenever motion manager is re-enabled.
    @Published public private(set) var initialDeviceRotation: Quat? = nil
    
    /// Rotation that moves content to the closest xy axis to the one the device is pointing at.
    ///
    /// Used by views with `isShowingInFourDirections` active. The value is the same for every view so it's calculated once per motion update and it only changes when the device crosses a 45 degree boundary.
    ///
    /// Device reference frame.
    @Published private(set) var cloneRotation: Quat = .identity
    
    /// True if ``cloneRotation`` changed on the most recent motion update.
    ///
    /// Used to suppress the smoothing animation for that update as the clone rotation snaps between 90 degree intervals and animating it would sweep the view around instead. This is deliberately not published as it's only read during view updates that are already triggered by ``quaternion``.
    private(set) var cloneRotationDidChange: Bool = false
    
    /// Rotation from initial device rotation to current.
    public var deltaRotation: Quat {
        guard let initialDeviceRotation = initialDeviceRotation else {
            return .identity
        }
        
        return (quaternion * initialDeviceRotation.inverse)
    }
    
    /// Clears the initial device rotation so the next motion update becomes the new zero position.
    func resetInitialRotation() {
        initialDeviceRotation = nil
    }
    
    /// Stores a new device rotation.
    /// - Parameter quaternion: Rotation of the device relative to zero position.
    func update(quaternion: Quat) {
        if initialDeviceRotation == nil {
            initialDeviceRotation = quaternion
        }
        
        /// This only changes when the device crosses a 45 degree boundary.
        let cloneRotation = Self.cloneRotation(for: quaternion)
        cloneRotationDidChange = self.cloneRotation != cloneRotation
        if cloneRotationDidChange {
            self.cloneRotation = cloneRotation
        }
        
        /// Set without animation so every observing view is invalidated once per motion update with a single transaction. Smoothing between updates is applied by the view that needs it in ``DeviceRotationEffectViewModifier``.
        self.quaternion = quaternion
    }
    
    /// Calculates the rotation that moves content to the closest xy axis to the one the device is pointing at.
    /// - Parameter quaternion: Rotation of the device relative to zero position.
    /// - Returns: A rotation around the z axis of 0, 90, 180, or -90 degrees. (device reference frame)
    static func cloneRotation(for quaternion: Quat) -> Quat {
        // start with a vector pointing straight down
        let originVector = Vec3(x: 0, y: 0, z: -1)
        
        // rotate the vector by the device orientation to see where the bottom of the device is pointing
        let rotatedVector = quaternion.rotating(originVector)
        
        let angle: Angle
        // check if the device is pointing more towards the x or y axis
        if abs(rotatedVector.x) > abs(rotatedVector.y) {
            // check which way it's pointing on the x axis and provide the appropriate rotation
            if rotatedVector.x >= 0 {
                // rotate -90 degrees
                angle = .radians(-.pi / 2)
            } else {
                // rotate 90 degrees
                angle = .radians(.pi / 2)
            }
        } else {
            // check which way it's pointing on the y axis and provide the appropriate rotation
            if rotatedVector.y >= 0 {
                // rotate 0 degrees
                angle = .zero
            } else {
                // rotate 180 degrees
                angle = .radians(.pi)
            }
        }
        
        return Quat(angle: angle, axis: .zAxis)
    }
}
