//
//  ShimmerView.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2021-05-25.
//

import SwiftUI

/// An elliptical gradient that rotates in 3D space based on device orientation
///
/// Takes all available space similar to `Color`
public struct ShimmerView: View {
    @EnvironmentObject private var motionManager: MotionManager
    @Environment(\.colorScheme) var colorScheme
    
    let mode: ShimmerMode
    let light: ShimmerLight
    
    /// Creates a shimmering view based on device orientation
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled. (default: `.on`)
    ///   - light: The light being caught, including the color it's drawn in, the background behind it, and where it sits in front of the device.
    public init(mode: ShimmerMode? = nil, light: ShimmerLight) {
        self.mode = mode ?? .on
        self.light = light
    }
    
    /// Creates a shimmering view based on device orientation
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled. (default: `.on`)
    ///   - color: ShimmerLight color
    ///   - background: Background color
    public init(mode: ShimmerMode? = nil, color: Color, background: Color) {
        self.init(mode: mode, light: ShimmerLight(color: color, background: background))
    }
    
    /// Creates a shimmering view based on device orientation
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Parameters:
    ///   - isOn: Is shimmer enabled.
    ///   - color: ShimmerLight color
    ///   - background: Background color
    @available(*, deprecated, message: "Use init(mode:color:background:) with .isOn(isOn). One mode parameter covers every way a shimmer can be on or off, including a Bool.")
    public init(isOn: Bool, color: Color, background: Color) {
        self.init(mode: .isOn(isOn), color: color, background: background)
    }
    
    var isShimmering: Bool {
        motionManager.isDetectingMotion && mode.isOn(colorScheme: colorScheme)
    }
    
    public var body: some View {
        let _ = Self.printChangesIfEnabled()
        light.background
            .overlay {
                VStack {
                    if isShimmering {
                        LookingGlass(
                            .reflection,
                            distance: light.distance,
                            perspective: 0,
                            pitch: light.pitch,
                            yaw: light.yaw,
                            localRoll: light.rollAngle,
                            isShowingInFourDirections: true
                        ) {
                            RadialGradient(
                                gradient: light.gradient,
                                center: .center,
                                startRadius: light.startRadius,
                                endRadius: light.endRadius
                            )
                            .frame(width: light.endRadius * 2, height: light.endRadius * 2)
                            .scaleEffect(light.gradientScale, anchor: .center)
                        }
                        .clipped()
                        
                    }
                }
                /// This ensures the shimmering effect does not change the content shape for hit testing and accessibility purporses.
                .contentShape(EmptyShape())
            }
            .ifAvailable {
                /// Even though allowed dynamic range is available in iOS 17, we only use it in iOS 26+ so no point enabling it in lower versions.
                if #available(iOS 26.0, *) {
                    $0.transformEnvironment(\.allowedDynamicRange) { allowedDynamicRange in
                        if light.isHDREnabled {
                            /// Dynamic range is only set if HDR is on and is untouched otherwise
                            allowedDynamicRange = .constrainedHigh
                        }
                    }
                }
            }
    }
}
