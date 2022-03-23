//
//  ParallaxView.swift
//  
//
//  Created by Ryan Lintott on 2022-03-23.
//

import FirebladeMath
import SwiftUI

struct ParallaxViewModifier: ViewModifier {
    @EnvironmentObject var motionManager: MotionManager

    let multiplier: CGFloat
    let maxOffset: CGFloat?
    
    var parallaxOffset: CGSize {
        guard let deltaRotation = motionManager.deltaRotation else {
            return .zero
        }

        let x = -min(maxOffset ?? .infinity, CGFloat(deltaRotation.yaw) * multiplier)
        let y = -min(maxOffset ?? .infinity, CGFloat(deltaRotation.pitch) * multiplier)
        
        return CGSize(width: x, height: y)
    }
    
    func body(content: Content) -> some View {
        content
            .offset(parallaxOffset)
    }
}

public extension View {
    func parallax(multiplier: CGFloat = 10, maxOffset: CGFloat? = nil) -> some View {
        modifier(ParallaxViewModifier(multiplier: multiplier, maxOffset: maxOffset))
    }
}
