//
//  ParallaxView.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2022-03-23.
//

import SwiftUI

struct ParallaxViewModifier: ViewModifier {
    /// Taken from the environment, so this effect reads the configuration of the scene containing it. Like every other effect in this package it requires a ``SwiftUICore/View/motionManager(updateInterval:disabled:)`` modifier above it and traps without one.
    @EnvironmentObject private var motionManager: MotionManager
    @EnvironmentObject private var deviceMotion: DeviceMotion

    let multiplier: CGFloat
    let maxOffset: CGFloat?
    
    var deltaScreenRotation: Quat {
        /// all rotations are provided in the device reference frame
        /// Rotations occur in reverse order
        /// 1. Reference frame is changed from screen to device (x and z flip)
        /// 2. result is rotated by the delta between the initial rotation and the current rotation
        /// 3. result is rotated by the inverse of the interface rotation to counteract any interface orientation changes
        (deviceMotion.interfaceRotation.inverse * deviceMotion.deltaRotation)
            .deviceToScreenReferenceFrame
    }
    
    var parallaxOffset: CGSize {
        guard motionManager.isDetectingMotion else { return .zero }
        
        let maxOffset = maxOffset ?? .infinity
        
        let x = -min(max(-maxOffset, deltaScreenRotation.yaw.radians * multiplier), maxOffset)
        let y = min(max(-maxOffset, deltaScreenRotation.pitch.radians * multiplier), maxOffset)
        
        return CGSize(width: x, height: y)
    }
    
    func body(content: Content) -> some View {
        let _ = Self.printChangesIfEnabled()
        content
            .offset(parallaxOffset)
            .animation(deviceMotion.animation, value: parallaxOffset)
    }
}

public extension View {
    /// Moves the view to create a parallax effect based on device orientation.
    ///
    /// - Requires: ``motionManager(updateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Parameters:
    ///   - multiplier: How much to move the view. Distance is the radians of the rotation multiplied by this multiplier.
    ///   - maxOffset: Clamps the movement to a maximum distance in x and y directions..
    /// - Returns: The view moved to create a parallax effect based on device orientation.
    func parallax(multiplier: CGFloat = 50, maxOffset: CGFloat? = nil) -> some View {
        modifier(ParallaxViewModifier(multiplier: multiplier, maxOffset: maxOffset))
    }
}
