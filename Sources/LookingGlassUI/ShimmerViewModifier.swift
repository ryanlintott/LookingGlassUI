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
    
    init(mode: ShimmerMode? = nil, color: Color, background: Color? = nil, blendMode: BlendMode? = nil) {
        self.mode = mode ?? .on
        self.color = color
        
        if let background = background {
            self.background = background
            self.blendMode = blendMode ?? .normal
        } else {
            self.background = .clear
            self.blendMode = blendMode ?? .screen
        }
    }
    
    var isShimmering: Bool {
        motionManager.updateInterval > 0 && mode.isOn(colorScheme: colorScheme)
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        if isShimmering {
            content
                .overlay(
                    ShimmerView(color: color, background: background)
                        .blendMode(blendMode)
                        .allowsHitTesting(false)
                )
                .mask(content)
                .matchedGeometryEffect(id: "content", in: namespace)
        } else {
            content
                .matchedGeometryEffect(id: "content", in: namespace)
        }
    }
}

public extension View {
    /// Add a shimmer effect to the view
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled (on by default)
    ///   - color: Shimmer color
    ///   - background: Background color (default: `.clear`)
    ///   - blendMode: How shimmer will blend with other views. (default: `.normal` when background is provided and `.screen` when not)
    /// - Returns: A view with a shimmer effect overlayed that is masked by the same view
    func shimmer(mode: ShimmerMode? = nil, color: Color, background: Color? = nil, blendMode: BlendMode? = nil) -> some View {
        self.modifier(ShimmerViewModifier(mode: mode, color: color, background: background, blendMode: blendMode))
    }
    
    /// Add a shimmer effect to the view
    /// - Parameters:
    ///   - isOn: Is shimmer enabled (default: `true`)
    ///   - color: Shimmer color
    ///   - background: Background color (default: `.clear`)
    ///   - blendMode: How shimmer will blend with other views. (default: `.normal` when background is provided and `.screen` when not)
    /// - Returns: A view with a shimmer effect overlayed that is masked by the same view
    func shimmer(isOn: Bool, color: Color, background: Color? = nil, blendMode: BlendMode? = nil) -> some View {
        self.modifier(ShimmerViewModifier(mode: isOn ? .on : .off, color: color, background: background, blendMode: blendMode))
    }
}
