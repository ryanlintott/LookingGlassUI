//
//  DeviceMotion.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-24.
//

import SwiftUI

/// The rotation of the device, updated on every motion update.
///
/// Read this from the environment. ``SwiftUICore/View/motionManager(updateInterval:disabled:)`` places it there alongside ``MotionManager``.
///
/// ```swift
/// @EnvironmentObject var deviceMotion: DeviceMotion
/// ```
///
/// These values are shared by every scene and change with the device rather than with any one scene's configuration, which is what separates them from ``MotionManager``. They also change many times a second: `ObservableObject` invalidates every observing view whenever any published property changes, so a view that reads only a scene's configuration would be re-evaluated on every motion update if these lived on the manager.
@MainActor
public final class DeviceMotion: ObservableObject {
    /// The one instance every scene reads, since the device it describes is shared by all of them.
    static let shared = DeviceMotion()
    
    private init() { }
    
    /// Rotation of device relative to zero position.
    ///
    /// This value steps once per motion update with no smoothing. Views that need smooth movement between updates animate it themselves, as `.deviceRotationEffect()` does:
    ///
    /// ```swift
    /// .animation(deviceMotion.animation, value: deviceMotion.quaternion)
    /// ```
    @Published public private(set) var quaternion: Quat = .identity
    
    /// Rotation from zero to initial position of device when motion updates started.
    ///
    /// Reset whenever the interface orientation changes, so ``deltaRotation`` measures from where the device was when the interface last settled rather than carrying a ninety degree step across the rotation. The next motion update after a reset becomes the new zero position.
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
    
    /// The orientation the interface is currently showing.
    ///
    /// This follows the interface rather than the device, so it stays correct while the device is lying flat and is right from launch in any orientation.
    ///
    /// Nil until a window scene reports a known orientation. `UIInterfaceOrientation.unknown` is never stored: a scene that cannot say which way it is facing leaves the last known orientation in place rather than resetting the world to portrait.
    @Published public private(set) var interfaceOrientation: UIInterfaceOrientation? = nil

    /// The interval the shared motion service is running at, in seconds.
    ///
    /// This is the fastest interval any live scene needs, so it can be shorter than the ``MotionManager/preferredUpdateInterval`` a given scene asked for. Zero while the service is stopped.
    @Published public private(set) var activeUpdateInterval: TimeInterval = 0

    /// A linear animation whose duration matches the rate samples actually arrive at.
    ///
    /// Apply this to values derived from ``quaternion`` to smooth the transition between motion samples.
    ///
    /// ```swift
    /// .animation(deviceMotion.animation, value: deviceMotion.quaternion)
    /// ```
    public var animation: Animation {
        .linear(duration: activeUpdateInterval)
    }

    /// The quaternion that compensates for the current interface orientation.
    ///
    /// Use this rotation when converting device-reference motion into screen-relative motion.
    public var interfaceRotation: Quat {
        interfaceOrientation?.rotation ?? .identity
    }
    
    /// The rotation of the screen, in the device reference frame.
    ///
    /// ``quaternion`` says where the device is pointing and ``interfaceRotation`` says how the interface sits on it, so composing the two gives where the screen itself is facing however the device is held and whichever way the interface has turned.
    ///
    /// Its inverse is what brings content back to rest against the screen, which is what the rotation effects in this package apply before placing content at a real-world angle.
    public var interfaceAlignedRotation: Quat {
         quaternion * interfaceRotation
    }

    /// Rotation from initial device rotation to current.
    public var deltaRotation: Quat {
        guard let initialDeviceRotation else {
            return .identity
        }
        
        return (quaternion * initialDeviceRotation.inverse)
    }
    
    /// Clears the initial device rotation so the next motion update becomes the new zero position.
    func resetInitialRotation() {
        initialDeviceRotation = nil
    }

    /// Stores the orientation the interface is showing and re-zeroes the rotation when it differs from the one already stored.
    ///
    /// - Parameter interfaceOrientation: The window scene's interface orientation.
    /// - Returns: `true` when a different orientation was applied; otherwise, `false`. The caller restarts the sensor on `true`, so an unchanged orientation must report `false` or every notification that reads the orientation restarts it.
    func setInterfaceOrientation(_ interfaceOrientation: UIInterfaceOrientation) -> Bool {
        guard self.interfaceOrientation != interfaceOrientation else { return false }

        self.interfaceOrientation = interfaceOrientation
        resetInitialRotation()
        return true
    }

    /// Stores the interval the shared motion service is running at.
    /// - Parameter activeUpdateInterval: Interval between motion samples in seconds, or zero while the service is stopped.
    func setActiveUpdateInterval(_ activeUpdateInterval: TimeInterval) {
        guard self.activeUpdateInterval != activeUpdateInterval else { return }

        self.activeUpdateInterval = activeUpdateInterval
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
    
    /// The device's z axis rotation rounded to the nearest 90 degrees (zero, 90, 180, or -90 degrees).
    ///
    /// This is the rotation about the z axis that turns the positive y axis onto whichever horizontal axis a vector rotated by this quaternion would point towards. It changes only when this rotation crosses a 45 degree boundary and starts pointing more towards another axis.
    ///
    /// Used by effects with `isShowingInFourDirections` active, where snapping to the nearest quarter turn is what keeps a copy of the content facing the viewer.
    private static func cloneRotation(for quaternion: Quat) -> Quat {
        // start with a vector pointing straight down. This is the direction a device points when it lays flat on the table.
        let originVector = Vec3(x: 0, y: 0, z: -1)

        // rotate the vector by this quaternion to see where the device is pointing
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
        // a rotation that will turn a vector pointing at the positive Y axis towards whatever axis is closest.
        return Quat(angle: angle, axis: .zAxis)
    }
}
