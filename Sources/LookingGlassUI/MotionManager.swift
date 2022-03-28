//
//  MotionManager.swift
//  ReflectiveUI
//
//  Created by Ryan Lintott on 2020-09-17.
//

import CoreMotion
import FirebladeMath
import SwiftUI

public class MotionManager: ObservableObject {
    public static let defaultUpdateInterval: TimeInterval = 0.1
    static let motionQueue = OperationQueue()
    static let screenSize = UIScreen.main.bounds.size
    static let maxScreenDimension = max(MotionManager.screenSize.height, MotionManager.screenSize.width)
    
    private let cmManager = CMMotionManager()

    // set to 0 for off
    @Published public private(set) var updateInterval: TimeInterval {
        didSet {
            toggleIfNeeded()
        }
    }
    
    @Published public private(set) var disabled: Bool = false {
        didSet {
            toggleIfNeeded()
        }
    }
    
    /// Rotation of device relative to zero position. Value is updated with SwiftUI animation to smooth between update intervals.
    @Published public private(set) var animatedQuaternion: Quat4f = .identity
    
    /// Rotation of device relative to zero position. Value is updated based on update intervals without animation or smoothing.
    @Published public private(set) var quaternion: Quat4f = .identity
    
    /// Rotation from zero to initial position of device when motion updates started.
    ///
    /// This value is reset whenever motion manager is re-enabled.
    @Published public private(set) var initialDeviceRotation: Quat4f? = nil
    
    /// Rotation from initial device rotation to current.
    public var deltaRotation: Quat4f {
        guard let initialDeviceRotation = initialDeviceRotation else {
            return .identity
        }
        
        return (animatedQuaternion * initialDeviceRotation.inverse)
    }
    
    // quaternion representing the interface rotation based on the deviceOrientation with some double-checking
    // note that the interface rotates in the opposite direction to the device to compensate
    // device reference frame
    public var interfaceRotation: Quat4f {
        switch deviceOrientation {
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
    
    @Published public var deviceOrientation: UIDeviceOrientation = .unknown
    
    public init(updateInterval: TimeInterval = defaultUpdateInterval) {
        self.updateInterval = updateInterval

        toggleIfNeeded()
    }
    
    deinit {
        cmManager.stopDeviceMotionUpdates()
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
        }
    }
    
    /// Sets the update interval to the value specified
    /// - Parameter newUpdateInterval: New update interval
    public func setUpdateInterval(_ newUpdateInterval: TimeInterval) {
        if updateInterval != newUpdateInterval {
            updateInterval = newUpdateInterval
        }
    }
    
    /// Sets the disabled property to the value specified
    /// - Parameter newDisabled: New disabled value.
    public func setDisabled(_ newDisabled: Bool) {
        if disabled != newDisabled {
            disabled = newDisabled
        }
    }
    
    /// Restarts motion updates
    public func restart() {
        cmManager.stopDeviceMotionUpdates()        
        toggleIfNeeded()
    }
    
    /// Toggles motion updates off if on or on if off (and not disabled and update interval greater than zero).
    private func toggleIfNeeded() {
        if cmManager.isDeviceMotionActive {
            cmManager.stopDeviceMotionUpdates()
        }
        
        guard updateInterval > 0 && !disabled else { return }

        cmManager.deviceMotionUpdateInterval = updateInterval

        cmManager.startDeviceMotionUpdates(to: .main) { motionData, error in
            if let motionData = motionData {
                let quaternion = motionData.attitude.quaternion.quat4f
                
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
