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
    @EnvironmentObject var motionManager: MotionManager
    @Environment(\.colorScheme) var colorScheme
    
    let mode: ShimmerMode
    let color: Color
    let background: Color

    let startRadius: CGFloat = 5
    let endRadius: CGFloat = 125
    let scale: CGFloat = 5
    let aspectRatio: CGFloat = 0.5
    let distance: CGFloat = 4000
    let pitch: Angle = .degrees(45)
    let yaw: Angle = .zero
    let localRoll: Angle = .degrees(-30)
    
    /// Creates a shimmering view based on device orientation
    ///
    /// - Requires: ``motionManager(updateInterval:disabled:)`` must be added only once in your app somewhere above this view in the heirarchy.
    ///
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled. (default: `.on`)
    ///   - color: Shimmer color
    ///   - background: Background color
    public init(mode: ShimmerMode? = nil, color: Color, background: Color) {
        self.mode = mode ?? .on
        self.color = color
        self.background = background
    }
    
    /// Creates a shimmering view based on device orientation
    ///
    /// - Requires: ``motionManager(updateInterval:disabled:)`` must be added only once in your app somewhere above this view in the heirarchy.
    ///
    /// - Parameters:
    ///   - isOn: Is shimmer enabled.
    ///   - color: Shimmer color
    ///   - background: Background color
    public init(isOn: Bool, color: Color, background: Color) {
        self.init(mode: isOn ? .on : .off, color: color, background: background)
    }
    
    var isShimmering: Bool {
        motionManager.updateInterval > 0 && mode.isOn(colorScheme: colorScheme)
    }
    
    public var body: some View {
        background
            .overlay(
                VStack {
                    if isShimmering {
                        LookingGlass(
                            .reflection,
                            distance: distance,
                            perspective: 0,
                            pitch: pitch,
                            yaw: yaw,
                            localRoll: localRoll,
                            isShowingInFourDirections: true
                        ) {
                            RadialGradient(gradient: Gradient(colors: [color, background]), center: .center, startRadius: startRadius, endRadius: endRadius)
                                .frame(width: endRadius * 2, height: endRadius * 2)
                                .scaleEffect(x: scale * aspectRatio, y: scale / aspectRatio, anchor: .center)
                        }
                        .clipped()
                    }
                }
                /// This ensures the shimmering effect does not change the content shape for hit testing and accessibility purporses.
                    .contentShape(EmptyShape())
            )
    }
}
