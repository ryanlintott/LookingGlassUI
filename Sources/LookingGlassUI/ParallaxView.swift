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
    
    var rotation: Quat {
        deviceMotion.deltaRotation
    }
    
    var parallaxOffset: CGSize {
        guard motionManager.isDetectingMotion else { return .zero }
        
        let maxOffset = maxOffset ?? .infinity
        
        let x = rotation.yaw.radians * multiplier
        let y = -rotation.pitch.radians * multiplier
        
        let vector = Vec3(x: x, y: y, z: 0).limited(to: maxOffset)
        
        return CGSize(width: vector.x, height: vector.y)
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
    ///   - maxOffset: Limits the movement to a maximum distance from the resting position, in any direction.
    /// - Returns: The view moved to create a parallax effect based on device orientation.
    func parallax(multiplier: CGFloat = 50, maxOffset: CGFloat? = nil) -> some View {
        modifier(ParallaxViewModifier(multiplier: multiplier, maxOffset: maxOffset))
    }
}
