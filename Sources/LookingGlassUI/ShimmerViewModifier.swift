//
//  ShimmerViewModifier.swift
//  ReflectiveUI
//
//  Created by Ryan Lintott on 2020-09-17.
//

import FirebladeMath
import SwiftUI

@available(iOS 14, *)
struct ShimmerViewModifier: ViewModifier {
    @EnvironmentObject var motionManager: MotionManager
    @Environment(\.colorScheme) var colorScheme
    
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
    
    @ViewBuilder func body(content: Content) -> some View {
        content
            .overlay(
                ShimmerView(color: color, background: background)
                    .blendMode(blendMode)
            )
            .mask(
                Group {
                    if isShimmering {
                        content
                    } else {
                        Color.white
                    }
                }
            )
    }
}

@available(iOS 14, *)
public extension View {
    func shimmer(mode: ShimmerMode? = nil, color: Color, background: Color? = nil, blendMode: BlendMode? = nil) -> some View {
        self.modifier(ShimmerViewModifier(mode: mode, color: color, background: background, blendMode: blendMode))
    }
    
    func shimmer(isOn: Bool, color: Color, background: Color? = nil, blendMode: BlendMode? = nil) -> some View {
        self.modifier(ShimmerViewModifier(mode: isOn ? .on : .off, color: color, background: background, blendMode: blendMode))
    }
}
