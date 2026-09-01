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

    let distance: CGFloat
    let maxOffset: CGFloat?
    
    var parallaxOffset: CGSize {
        /// Check if this view heirarchy is detecting motion
        guard motionManager.isDetectingMotion else { return .zero }

        return deviceMotion.deltaRotation.parallaxOffset(distance: distance, maxOffset: maxOffset)
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
    ///   - distance: How far in front of the screen the view is treated as resting, in points. The view moves as that point would, so this is also the furthest it can travel. A negative distance rests the view behind the screen and moves it the other way.
    ///   - maxOffset: Limits the movement to a maximum distance from the resting position, in any direction.
    /// - Returns: The view moved to create a parallax effect based on device orientation.
    func parallax(distance: CGFloat, maxOffset: CGFloat? = nil) -> some View {
        modifier(ParallaxViewModifier(distance: distance, maxOffset: maxOffset))
    }

    @available(*, unavailable, renamed: "parallax(distance:maxOffset:)", message: "The view is now treated as a point resting this many points in front of the screen rather than a factor applied to the angle turned, so `distance` is what it has always been measured in.")
    func parallax(multiplier: CGFloat = 50, maxOffset: CGFloat? = nil) -> some View {
        parallax(distance: multiplier, maxOffset: maxOffset)
    }
}
