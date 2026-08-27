//
//  DeviceMotion.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-24.
//

import SwiftUI

/// The rotation of the device, updated on every motion update.
///
/// Access this via ``MotionManager/deviceMotion`` or from the environment. ``SwiftUICore/View/motionManager(updateInterval:disabled:)`` places it there alongside ``MotionManager``.
///
/// ```swift
/// @EnvironmentObject var deviceMotion: DeviceMotion
/// ```
///
/// These values are shared by every scene and change with the device rather than with any one scene's configuration, which is what separates them from ``MotionManager``. They also change many times a second: `ObservableObject` invalidates every observing view whenever any published property changes, so a view that reads only a scene's configuration would be re-evaluated on every motion update if these lived on the manager.
@MainActor
public final class DeviceMotion: ObservableObject {
    /// The service shared by every scene in the app.
    static let shared = DeviceMotion()
    
    init() { }
    
    /// Rotation of device relative to zero position.
    ///
    /// This value steps once per motion update with no smoothing. Views that need smooth movement between updates animate it themselves, as `.deviceRotationEffect()` does:
    ///
    /// ```swift
    /// .animation(motionManager.animation, value: deviceMotion.quaternion)
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
    /// This follows the interface rather than the device, so it stays correct while the device is lying flat and is right from launch in any orientation. Once a known value is added it will not update with unknown values.
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
    
    public var interfaceAlignedRotation: Quat {
        interfaceRotation.inverse * quaternion.inverse
    }

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

    /// Stores the orientation the interface is showing.
    /// - Parameter interfaceOrientation: The window scene's interface orientation.
    func setInterfaceOrientation(_ interfaceOrientation: UIInterfaceOrientation) {
        guard self.interfaceOrientation != interfaceOrientation else { return }

        self.interfaceOrientation = interfaceOrientation
        resetInitialRotation()
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
        let cloneRotation = quaternion.cloneRotation
        cloneRotationDidChange = self.cloneRotation != cloneRotation
        if cloneRotationDidChange {
            self.cloneRotation = cloneRotation
        }
        
        /// Set without animation so every observing view is invalidated once per motion update with a single transaction. Smoothing between updates is applied by the view that needs it in ``DeviceRotationEffectViewModifier``.
        self.quaternion = quaternion
    }
}
