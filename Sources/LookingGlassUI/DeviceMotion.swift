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
    
    /// The current orientation of the device relative to the zero position (laying flat).
    ///
    /// This value steps once per motion update with no smoothing. Views that need smooth movement between updates animate it themselves, as `.deviceRotationEffect()` does:
    ///
    /// ```swift
    /// .animation(deviceMotion.animation, value: deviceMotion.currentDeviceRotation)
    /// ```
    @Published public private(set) var currentDeviceRotation: Quat = .identity
    
    /// Where the device has settled over the last few seconds. ``deltaRotation`` is measured from here.
    ///
    /// Reset whenever the interface orientation changes, so ``deltaRotation`` measures from where the device was when the interface last settled rather than carrying a ninety degree step across the rotation. The next motion update after a reset becomes the new settled rotation.
    ///
    /// Between resets this eases towards wherever the device is being held, over ``settlingDuration``. A turn the device makes and then keeps is given up rather than held against it forever, so the effects that measure from here return to rest instead of staying pushed to one side. See ``deltaRotation`` for why that matters.
    @Published public private(set) var settledDeviceRotation: Quat? = nil

    /// The first of the two stages ``settledDeviceRotation`` settles through.
    ///
    /// Deliberately not published. No view reads it, and publishing it would invalidate every observer a second time on every motion update.
    private var settlingDeviceRotation: Quat? = nil
    
    /// Rotation that moves content to the closest xy axis to the one the device is pointing at.
    ///
    /// Used by views with `isShowingInFourDirections` active. The value is the same for every view so it's calculated once per motion update and it only changes when the device crosses a 45 degree boundary.
    ///
    /// Device reference frame.
    @Published private(set) var cloneRotation: Quat = .identity
    
    /// True if ``cloneRotation`` changed on the most recent motion update.
    ///
    /// Used to suppress the smoothing animation for that update as the clone rotation snaps between 90 degree intervals and animating it would sweep the view around instead. This is deliberately not published as it's only read during view updates that are already triggered by ``currentDeviceRotation``.
    private(set) var cloneRotationDidChange: Bool = false
    
    /// The orientation the interface is currently showing.
    ///
    /// This follows the interface rather than the device, so it stays correct while the device is lying flat and is right from launch in any orientation.
    ///
    /// Nil until a window scene reports a known orientation. `UIInterfaceOrientation.unknown` is never stored: a scene that cannot say which way it is facing leaves the last known orientation in place rather than resetting the world to portrait.
    @Published public private(set) var interfaceOrientation: UIInterfaceOrientation? = nil

    /// The interval the shared motion service is running at, in seconds.
    ///
    /// This is the fastest interval any live scene needs, so it can be shorter than the ``MotionManager/preferredUpdateInterval`` a given scene asked for. Zero when no scene needs motion updates.
    @Published public private(set) var updateInterval: TimeInterval = 0

    /// How long ``settledDeviceRotation`` takes to give up most of a turn the device makes and then holds.
    ///
    /// A turn of the device is either the viewer moving the screen relative to their eyes, which the effects reading ``deltaRotation`` should follow, or the viewer turning themselves and carrying the screen with them, which they should ignore. Device attitude alone cannot tell the two apart: turning on the spot and tipping the screen towards one side are the same rotation about the same vertical axis, and only where the viewer's eyes are separates them.
    ///
    /// Time is the one signal that does separate them in practice. A tilt is made and given back within a moment, while turning around, walking, or sitting down is held. Easing the settled rotation towards the device over a few seconds follows the first and gives up the second, without needing to know which it was.
    ///
    /// This is the time constant of each of the two stages the settling runs through, rather than of the whole of it. One stage alone moves fastest the instant the device stops turning, which reads as the view being snatched back the moment a tilt ends. Two stages start from a standstill and build up, so the view holds briefly and then eases back, while taking about as long overall to give up a turn that is held.
    ///
    /// Set it with ``setSettlingDuration(_:)``. Zero or less stops the settling altogether and holds ``settledDeviceRotation`` where it is.
    @Published public private(set) var settlingDuration: TimeInterval = 2

    /// A linear animation whose duration matches the rate samples actually arrive at.
    ///
    /// Apply this to values derived from ``currentDeviceRotation`` to smooth the transition between motion samples.
    ///
    /// ```swift
    /// .animation(deviceMotion.animation, value: deviceMotion.currentDeviceRotation)
    /// ```
    public var animation: Animation {
        .linear(duration: updateInterval)
    }

    /// The quaternion that compensates for the current interface orientation.
    ///
    /// Use this rotation when converting device-reference motion into screen-relative motion.
    public var interfaceRotation: Quat {
        interfaceOrientation?.rotation ?? .identity
    }

    /// The rotation from the settled rotation to the current rotation of the interface. Used to rotate a SwiftUI view to match the orientation the device has settled at. Measured from ``settledDeviceRotation``, which is reset whenever the interface orientation changes and eases towards the device between resets, over ``settlingDuration``. Screen reference frame.
    public var deltaRotation: Quat {
        guard let settledDeviceRotation else { return .identity }
        return (interfaceRotation.inverse * currentDeviceRotation.inverse * settledDeviceRotation * interfaceRotation).deviceToScreenReferenceFrame
    }
    
    /// Used to rotate a SwiftUI view so it appears locked to an orientation in the real world.
    /// - Parameter offset: The rotational offset from a flat position with the top pointing away from the user. Device reference frame.
    /// - Parameter isShowingInFourDirections: If enabled the view will show in four different places as the phone turns in a full circle. When the device turns more than 45 degrees on the z axis away from one of the x or y axis directions the view will rotate 90 degrees towards the new closest axis direction.
    /// - Returns: The rotation to use to rotate a swiftUI view into a real world location with a rotation effect modifier. Screen reference frame.
    public func interfaceToWorldRotation(offset: Quat, isShowingInFourDirections: Bool = false) -> Quat {
        
        let cloneRotation = isShowingInFourDirections ? cloneRotation : .identity
        
        /// All rotations are provided in the device reference frame
        /// 0. Start with content on the phone in the current position and orientation.
        /// 1. Rotate so that the top of content matches the top of the phone
        /// 2. Rotate back to the `.identity` position for the phone (face up)
        /// 3. Rotate to point the top of the interface for a phone in the `.identity` device position.
        /// 4. Rotate to the axis that best aligns with the current interface.
        /// 5. Rotate to the requested offset.
        /// 6. Translate all this rotation from device coordinates to screen coordinates
        return (interfaceRotation.inverse * currentDeviceRotation.inverse * interfaceRotation * cloneRotation * offset).deviceToScreenReferenceFrame
    }

    /// Stores the current interface orientation and clears the settled rotation when the orientation differs from the one already stored.
    ///
    /// - Parameter interfaceOrientation: The window scene's interface orientation.
    /// - Returns: `true` when a different orientation was applied; otherwise, `false`. The caller restarts the sensor on `true`, so an unchanged orientation must report `false` or every notification that reads the orientation restarts it.
    func setInterfaceOrientation(_ interfaceOrientation: UIInterfaceOrientation) -> Bool {
        guard self.interfaceOrientation != interfaceOrientation else { return false }

        resetSettledDeviceRotation()
        self.interfaceOrientation = interfaceOrientation
        return true
    }

    /// Stores the interval the shared motion service is running at.
    /// - Parameter updateInterval: Interval between motion samples in seconds, or zero while the service is stopped.
    func setUpdateInterval(_ updateInterval: TimeInterval) {
        guard self.updateInterval != updateInterval else { return }

        self.updateInterval = updateInterval
    }
    
    /// Stores how long ``settledDeviceRotation`` should take to move to a new position.
    ///
    /// Every scene reads one shared ``DeviceMotion``, so this sets the settling for all of them rather than for the scene that called it.
    ///
    /// Safe to change while motion updates are running. Each sample works out afresh how far to move from the duration and the interval, so nothing jumps; the settling simply carries on at the new rate from wherever it had reached.
    ///
    /// - Parameter settlingDuration: The time constant of each settling stage in seconds. Zero stops settling, holding ``settledDeviceRotation`` where it is until a reset.
    public func setSettlingDuration(_ settlingDuration: TimeInterval) {
        guard self.settlingDuration != settlingDuration else { return }

        self.settlingDuration = settlingDuration
    }

    /// Stores a current device rotation.
    /// - Parameter newDeviceRotation: Rotation of the device relative to Core Motion's own reference attitude.
    func setCurrentDeviceRotation(to newDeviceRotation: Quat) {
        updateSettledDeviceRotation(using: newDeviceRotation)
        updateCloneRotation(using: newDeviceRotation)
        
        /// Set without animation so every observing view is invalidated once per motion update with a single transaction. Smoothing between updates is applied by the view that needs it in ``DeviceRotationEffectViewModifier``.
        self.currentDeviceRotation = newDeviceRotation
    }
    
    private func updateCloneRotation(using newDeviceRotation: Quat) {
        /// The clone rotation uses the inverse of the interface rotation because in some orientations the top of the device might point in a completely different direction from the top of the interface.
        let cloneRotation = Self.cloneRotation(for: interfaceRotation.inverse * newDeviceRotation)
        cloneRotationDidChange = self.cloneRotation != cloneRotation
        if cloneRotationDidChange {
            self.cloneRotation = cloneRotation
        }
    }
    
    private func updateSettledDeviceRotation(using newDeviceRotation: Quat) {
        if let settlingDeviceRotation, let settledDeviceRotation {
            /// The first stage chases the device and the second chases the first, which is what keeps the second from setting off at full speed the moment the device stops.
            let settling = settlingDeviceRotation.slerp(to: newDeviceRotation, amount: settlingAmount)
            self.settlingDeviceRotation = settling
            /// Assigned before ``currentDeviceRotation`` below so both land in the same run loop turn and observing views are invalidated once for the pair.
            self.settledDeviceRotation = settledDeviceRotation.slerp(to: settling, amount: settlingAmount)
        } else {
            /// With nothing settled yet, the current rotation becomes it
            settlingDeviceRotation = newDeviceRotation
            settledDeviceRotation = newDeviceRotation
        }
    }
    
    /// Clears the settled rotation so the next motion update becomes the new one.
    func resetSettledDeviceRotation() {
        settlingDeviceRotation = nil
        settledDeviceRotation = nil
    }
    
    /// How far one settling stage moves towards the one it is chasing on a single sample, as a fraction of the remaining gap from zero to one.
    ///
    /// Each sample closes the same fraction of whatever gap is left, so a single stage sheds all but `1/e` of it over ``settlingDuration``, whatever rate samples happen to be arriving at. Two stages in series turn that into a gentler start for the same overall duration.
    private var settlingAmount: Double {
        /// A stopped service reports a zero interval. No time has passed as far as this is concerned, so the settled rotation stays where it is rather than snapping to the device on the next sample.
        guard updateInterval > 0, settlingDuration > 0 else { return 0 }

        return 1 - exp(-updateInterval / settlingDuration)
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
