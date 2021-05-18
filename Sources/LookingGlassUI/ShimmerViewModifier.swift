//
//  ShimmerViewModifier.swift
//  ReflectiveUI
//
//  Created by Ryan Lintott on 2020-09-17.
//

import FirebladeMath
import SwiftUI

@available(iOS 13, *)
public enum ShimmerMode {
    case on, lightModeOnly, darkModeOnly, off
    
    func isOn(colorScheme: ColorScheme) -> Bool {
        switch self {
        case .on:
            return true
        case .off:
            return false
        case .lightModeOnly:
            return colorScheme == .light
        case .darkModeOnly:
            return colorScheme == .dark
        }
    }
}

@available(iOS 14, *)
struct ShimmerViewModifier: ViewModifier {
    @EnvironmentObject var motionManager: MotionManager
    @Environment(\.colorScheme) var colorScheme
    
    let mode: ShimmerMode
    let color: Color
    let background: Color
    let blendMode: BlendMode

    let startRadius: CGFloat = 5
    let endRadius: CGFloat = 125
    let scale: CGFloat = 10
    let aspectRatio: CGFloat = 0.5
    let distance: CGFloat = 4000
    let pitch: Angle = .degrees(45)
    let roll: Angle = .degrees(0)
    let yaw: Angle = .degrees(30)
    
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
    
    @ViewBuilder func body(content: Content) -> some View {
        if motionManager.updateInterval > 0 && mode.isOn(colorScheme: colorScheme) {
            content
                .maskedOverlay(shimmer, blendMode: blendMode)

                    //For testing
//                    .maskedOverlay(Color.pink)
//                    .maskedOverlay(shimmer)
        } else {
            content
        }
    }
    
    var shimmer: some View {
        LookingGlass(.reflection, distance: distance, perspective: 0, pitch: pitch, roll: roll, yaw: yaw, isShowingInFourDirections: true) {
            RadialGradient(gradient: Gradient(colors: [color, background]), center: .center, startRadius: startRadius, endRadius: endRadius)
                .frame(width: endRadius * 2, height: endRadius * 2)
                .scaleEffect(x: scale * aspectRatio, y: scale / aspectRatio, anchor: .center)
        }
        .background(background)
        .allowsHitTesting(false)
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
