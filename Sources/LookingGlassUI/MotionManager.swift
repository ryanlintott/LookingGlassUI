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
    
    // set to 0 for off
    @Published public private(set) var updateInterval: TimeInterval = 0
    
    @Published public private(set) var disabled: Bool = false
    
    @Published public private(set) var deviceOrientation: UIDeviceOrientation = .unknown
    
    /// Rotation of device relative to zero position. Value is updated with SwiftUI animation to smooth between update intervals.
    @Published public private(set) var animatedQuaternion: Quat = .identity
    
    /// Rotation of device relative to zero position. Value is updated based on update intervals without animation or smoothing.
    @Published public private(set) var quaternion: Quat = .identity
    
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
    
    /// Stops motion updates. This must be run before deinit
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
                let quaternion = Quat(motionData.attitude.quaternion)
                
                if self.initialDeviceRotation == nil {
                    self.initialDeviceRotation = quaternion
                }
                
                self.quaternion = quaternion
                withAnimation(Animation.linear(duration: self.updateInterval)) {
                    self.animatedQuaternion = quaternion
                }
                
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
