//
//  MotionManager.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2020-09-17.
//

import CoreMotion
import SwiftUI

@MainActor
public class MotionManager: ObservableObject {
    /// Only one shared MotionManager should be used in an app
    static let shared = MotionManager()
    
    private init() { }
    
    static let motionQueue = OperationQueue()
    static let screenSize = UIScreen.main.bounds.size
    static let maxScreenDimension = max(MotionManager.screenSize.height, MotionManager.screenSize.width)
    
    private let cmManager = CMMotionManager()
    
    /// Set to true to print the reason each LookingGlassUI view updates.
    ///
    /// Each motion update is preceded by a numbered marker so the view updates that follow it can be attributed to that motion update. Useful for checking how many view updates each motion update triggers. Printing is slow enough to distort timings so use this to count updates, not to measure their cost. Has no effect outside debug builds.
    public static var isPrintingViewChanges: Bool = false
    
    /// Counts motion updates while ``isPrintingViewChanges`` is on.
    private static var motionUpdateCount: Int = 0
    
    // set to 0 for off
    @Published public private(set) var updateInterval: TimeInterval = 0
    
    @Published public private(set) var disabled: Bool = false
    
    @Published public private(set) var deviceOrientation: UIDeviceOrientation = .unknown
    
    /// Rotation of device relative to zero position. Value is updated with SwiftUI animation to smooth between update intervals.
    @Published public private(set) var animatedQuaternion: Quat = .identity
    
    /// Rotation of device relative to zero position. Value is updated based on update intervals without animation or smoothing.
    @Published public private(set) var quaternion: Quat = .identity
    
    /// Rotation that moves content to the closest xy axis to the one the device is pointing at.
    ///
    /// Used by views with `isShowingInFourDirections` active. The value is the same for every view so it's calculated once per motion update and it only changes when the device crosses a 45 degree boundary.
    ///
    /// Device reference frame.
    @Published private(set) var cloneRotation: Quat = .identity
    
    /// True if ``cloneRotation`` changed on the most recent motion update.
    ///
    /// Used to suppress the smoothing animation for that update as the clone rotation snaps between 90 degree intervals and animating it would sweep the view around instead. This is deliberately not published as it's only read during view updates that are already triggered by ``animatedQuaternion``.
    private(set) var cloneRotationDidChange: Bool = false
    
    /// Rotation from zero to initial position of device when motion updates started.
    ///
    /// This value is reset whenever motion manager is re-enabled.
    @Published public private(set) var initialDeviceRotation: Quat? = nil
    
    /// Rotation from initial device rotation to current.
    public var deltaRotation: Quat {
        guard let initialDeviceRotation = initialDeviceRotation else {
            return .identity
        }
        
        return (animatedQuaternion * initialDeviceRotation.inverse)
    }
    
    // quaternion representing the interface rotation based on the deviceOrientation with some double-checking
    // note that the interface rotates in the opposite direction to the device to compensate
    // device reference frame
    public var interfaceRotation: Quat {
        switch deviceOrientation {
        // top of device to the left
        case .landscapeLeft:
            return Quat(angle: .radians(-.pi / 2), axis: .zAxis)
        // top of device to the right
        case .landscapeRight:
            return Quat(angle: .radians(.pi / 2), axis: .zAxis)
        case .portraitUpsideDown:
            return Quat(angle: .radians(.pi), axis: .zAxis)
        default:
            return .identity
        }
    }
    
    /// True if update interval greater than zero and not disabled.
    public var isDetectingMotion: Bool {
        updateInterval > 0 && !disabled
    }
    
    /// The device screen size taking into account device orientation.
    var interfaceSize: CGSize {
        switch deviceOrientation {
        case .landscapeRight, .landscapeLeft:
            return CGSize(width: Self.screenSize.height, height: Self.screenSize.width)
        default:
            return Self.screenSize
        }
    }
    
    /// Changes the device orientation property if the new orientation is supported.
    public func changeDeviceOrientation() {
        let newOrientation = UIDevice.current.orientation

        guard deviceOrientation != newOrientation else {
            return
        }
        
        if InfoDictionary.supportedOrientations.contains(newOrientation) {
            initialDeviceRotation = nil
            self.deviceOrientation = newOrientation
            restartMotionUpdatesIfNeeded()
        }
    }
    
    /// Sets the update interval to the value specified
    /// - Parameter newUpdateInterval: New update interval
    public func setUpdateInterval(_ newUpdateInterval: TimeInterval) {
        if updateInterval != newUpdateInterval {
            updateInterval = newUpdateInterval
            restartMotionUpdatesIfNeeded()
        }
    }
    
    /// Sets the disabled property to the value specified
    /// - Parameter newDisabled: New disabled value.
    public func setDisabled(_ newDisabled: Bool) {
        if disabled != newDisabled {
            disabled = newDisabled
            restartMotionUpdatesIfNeeded()
        }
    }
    
    /// Method to update several properties at once.
    /// - Parameters:
    ///   - updateInterval: Time between motion updates.
    ///   - disabled: If true, motion updates are disabled.
    ///   - setDeviceOrientation: If true, device orientation is updated.
    public func startMotionUpdates(updateInterval: TimeInterval? = nil, disabled: Bool? = nil, setDeviceOrientation: Bool = false) {
        
        if let disabled, self.disabled != disabled {
            self.disabled = disabled
        }
        
        if let updateInterval, self.updateInterval != updateInterval {
            self.updateInterval = updateInterval
        }
        
        if setDeviceOrientation {
            let newOrientation = UIDevice.current.orientation
            if deviceOrientation != newOrientation,
               InfoDictionary.supportedOrientations.contains(newOrientation) {
                initialDeviceRotation = nil
                deviceOrientation = newOrientation
            }
        }
        
        restartMotionUpdatesIfNeeded()
    }
    
    /// Restarts motion updates
    public func restart() {
        restartMotionUpdatesIfNeeded()
    }
    
    /// Stops motion updates. This must be run before deinit. Currently this is done with `.onDisappear()` in the ``SwiftUICore/View/motionManager(updateInterval:disabled:)`` view modifier.
    public func stopMotionUpdates() {
        if cmManager.isDeviceMotionActive {
            cmManager.stopDeviceMotionUpdates()
        }
    }
    
    /// Calculates the rotation that moves content to the closest xy axis to the one the device is pointing at.
    /// - Parameter quaternion: Rotation of the device relative to zero position.
    /// - Returns: A rotation around the z axis of 0, 90, 180, or -90 degrees. (device reference frame)
    private static func cloneRotation(for quaternion: Quat) -> Quat {
        // start with a vector pointing straight down
        let originVector = Vec3(x: 0, y: 0, z: -1)
        
        // rotate the vector by the device orientation to see where the bottom of the device is pointing
        let rotatedVector = quaternion.rotating(originVector)
        
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
    
    /// Toggles motion updates off if on or on if off (and not disabled and update interval greater than zero).
    private func restartMotionUpdatesIfNeeded() {
        stopMotionUpdates()
        
        guard updateInterval > 0 && !disabled else { return }

        cmManager.deviceMotionUpdateInterval = updateInterval

        cmManager.startDeviceMotionUpdates(to: .main) { motionData, error in
            if let motionData = motionData {
                #if DEBUG
                if Self.isPrintingViewChanges {
                    Self.motionUpdateCount += 1
                    print("=== motion update \(Self.motionUpdateCount) ===")
                }
                #endif
                
                let quaternion = Quat(motionData.attitude.quaternion)
                
                if self.initialDeviceRotation == nil {
                    self.initialDeviceRotation = quaternion
                }
                
                /// This only changes when the device crosses a 45 degree boundary.
                let cloneRotation = Self.cloneRotation(for: quaternion)
                self.cloneRotationDidChange = self.cloneRotation != cloneRotation
                if self.cloneRotationDidChange {
                    self.cloneRotation = cloneRotation
                }
                
                /// Both values are set without animation so every observing view is invalidated once per motion update with a single transaction. Smoothing between updates is applied by the view that needs it in ``DeviceRotationEffectViewModifier`` which leaves `quaternion` free to deliver unanimated updates.
                self.quaternion = quaternion
                self.animatedQuaternion = quaternion
                
            } else if let error = error {
                print(error.localizedDescription)
            } else {
                print("Error - Unknown motion update error")
            }
        }
    }
}

struct MotionManager_Previews: PreviewProvider {
    static var previews: some View {
        Color.blue
            .motionManager(updateInterval: 0)
    }
}
