//
//  MotionManager.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2020-09-17.
//

import CoreMotion
import SwiftUI

/// Configuration for device motion updates.
///
/// Add ``SwiftUICore/View/motionManager(updateInterval:disabled:)`` once near the top of your view hierarchy rather than using this type directly. That modifier places this object and ``DeviceRotation`` in the environment.
///
/// The values here change rarely. The rotation of the device is on ``DeviceRotation`` so views reading only configuration aren't updated on every motion update.
@MainActor
public class MotionManager: ObservableObject {
    /// Only one shared MotionManager should be used in an app
    static let shared = MotionManager()
    
    private init() { }
    
    static let motionQueue = OperationQueue()
    
    /// The screen size in portrait orientation.
    ///
    /// `UIScreen.bounds` is reported in the current interface orientation and this value is captured once, so the fixed coordinate space is used instead. Its bounds always reflect a portrait-up orientation and are measured in points.
    static let portraitScreenSize = UIScreen.main.fixedCoordinateSpace.bounds.size
    
    static let maxScreenDimension = max(MotionManager.portraitScreenSize.height, MotionManager.portraitScreenSize.width)
    
    private let cmManager = CMMotionManager()
    
    /// The rotation of the device, updated on every motion update.
    ///
    /// Kept separate from this manager so views that read only configuration aren't re-evaluated on every motion update.
    public let deviceRotation = DeviceRotation()
    
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
    
    @available(*, unavailable, message: "Removed to improve performance. Use `motionManager.deviceRotation.quaternion` instead and apply animation as per the documentation for that property.")
    public var animatedQuaternion: Quat { fatalError() }
    
    @available(*, unavailable, message: "Moved to DeviceRotation. Read it from `motionManager.deviceRotation` or add `@EnvironmentObject var deviceRotation: DeviceRotation` to your view.")
    public var quaternion: Quat { fatalError() }
    
    @available(*, unavailable, message: "Moved to DeviceRotation. Read it from `motionManager.deviceRotation` or add `@EnvironmentObject var deviceRotation: DeviceRotation` to your view.")
    public var initialDeviceRotation: Quat? { fatalError() }
    
    @available(*, unavailable, message: "Moved to DeviceRotation. Read it from `motionManager.deviceRotation` or add `@EnvironmentObject var deviceRotation: DeviceRotation` to your view.")
    public var deltaRotation: Quat { fatalError() }
    
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
            return CGSize(width: Self.portraitScreenSize.height, height: Self.portraitScreenSize.width)
        default:
            return Self.portraitScreenSize
        }
    }
    
    /// Changes the device orientation property if the new orientation is supported.
    public func changeDeviceOrientation() {
        let newOrientation = UIDevice.current.orientation

        guard deviceOrientation != newOrientation else {
            return
        }
        
        if InfoDictionary.supportedOrientations.contains(newOrientation) {
            deviceRotation.resetInitialRotation()
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
                deviceRotation.resetInitialRotation()
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
                
                self.deviceRotation.update(quaternion: Quat(motionData.attitude.quaternion))
                
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
