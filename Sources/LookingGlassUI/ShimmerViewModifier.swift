//
//  ShimmerViewModifier.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2020-09-17.
//

import SwiftUI

struct ShimmerViewModifier: ViewModifier {
    @EnvironmentObject private var motionManager: MotionManager
    @Environment(\.colorScheme) private var colorScheme
    
    @Namespace private var namespace
    
    let mode: ShimmerMode
    let color: Color
    let background: Color
    let blendMode: BlendMode
    
    init(mode: ShimmerMode? = nil, color: Color, blendMode: BlendMode? = nil) {
        self.mode = mode ?? .on
        self.color = color
        self.background = .clear
        self.blendMode = blendMode ?? .screen
    }
    
    init(mode: ShimmerMode? = nil, color: Color, background: Color) {
        self.mode = mode ?? .on
        self.color = color
        self.background = background
        self.blendMode = .sourceAtop
    }
    
    var isShimmering: Bool {
        motionManager.updateInterval > 0 && mode.isOn(colorScheme: colorScheme)
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .overlay(
                VStack {
                    if isShimmering {
                        content
                            .hidden()
                            .overlay(
                                ShimmerView(color: color, background: background)
                            )
                            .mask(content)
                            .blendMode(blendMode)
                            .accessibilityHidden(true)
                            .allowsHitTesting(false)
                    }
                }
            )
    }
}

public extension View {
    /// Add a shimmer effect with a background masked to this view.
    ///
    /// - Requires: ``motionManager(updateInterval:disabled:)`` must be added only once in your app somewhere above this view in the heirarchy.
    ///
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled (default: `.on`)
    ///   - color: Shimmer color.
    ///   - background: Background color.
    /// - Returns: A shimmer effect with a background masked to this view.
    func shimmer(mode: ShimmerMode? = nil, color: Color, background: Color) -> some View {
        self.modifier(ShimmerViewModifier(mode: mode, color: color, background: background))
    }
    
    /// Add a shimmer effect with a background masked to this view.
    ///
    /// - Requires: ``motionManager(updateInterval:disabled:)`` must be added only once in your app somewhere above this view in the heirarchy.
    ///
    /// - Parameters:
    ///   - isOn: Is shimmer enabled (default: `true`)
    ///   - color: Shimmer color.
    ///   - background: Background color.
    /// - Returns: A shimmer effect with a background masked to this view.
    func shimmer(isOn: Bool, color: Color, background: Color) -> some View {
        self.modifier(ShimmerViewModifier(mode: isOn ? .on : .off, color: color, background: background))
    }
    
    /// Add a shimmer effect masked to this view with a specified blend mode.
    ///
    /// - Requires: ``motionManager(updateInterval:disabled:)`` must be added only once in your app somewhere above this view in the heirarchy.
    ///
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled (default: `.on`)
    ///   - color: Shimmer color
    ///   - blendMode: How shimmer will blend with other views. (default: `.screen`)
    /// - Returns: A view with a shimmer effect overlayed that is masked by the same view
    func shimmer(mode: ShimmerMode? = nil, color: Color, blendMode: BlendMode? = nil) -> some View {
        self.modifier(ShimmerViewModifier(mode: mode, color: color, blendMode: blendMode))
    }
    
    /// Add a shimmer effect masked to this view with a specified blend mode.
    ///
    /// - Requires: ``motionManager(updateInterval:disabled:)`` must be added only once in your app somewhere above this view in the heirarchy.
    ///
    /// - Parameters:
    ///   - isOn: Is shimmer enabled.
    ///   - color: Shimmer color
    ///   - blendMode: How shimmer will blend with other views. (default: `.screen`)
    /// - Returns: A view with a shimmer effect overlayed that is masked by the same view
    func shimmer(isOn: Bool, color: Color, blendMode: BlendMode? = nil) -> some View {
        self.modifier(ShimmerViewModifier(mode: isOn ? .on : .off, color: color, blendMode: blendMode))
    }
}
