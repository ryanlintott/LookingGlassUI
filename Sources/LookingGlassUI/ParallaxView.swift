//
//  ParallaxView.swift
//  
//
//  Created by Ryan Lintott on 2022-03-23.
//

import SwiftUI

struct ParallaxViewModifier: ViewModifier {
    @EnvironmentObject var motionManager: MotionManager

    let multiplier: CGFloat
    let maxOffset: CGFloat?
    
    var deltaScreenRotation: Quat {
        /// all rotations are provided in the device reference frame
        /// Rotations occur in reverse order
        /// 1. Reference frame is changed from screen to device (x and z flip)
        /// 2. result is rotated by the delta between the initial rotation and the current rotation
        /// 3. result is rotated by the inverse of the interface rotation to counteract any interface orientation changes
        return (motionManager.interfaceRotation.inverse * motionManager.deltaRotation).deviceToScreenReferenceFrame
    }
    
    var parallaxOffset: CGSize {
        guard motionManager.isDetectingMotion else {
            return .zero
        }
        
        let x = -min(maxOffset ?? .infinity, deltaScreenRotation.yaw.radians * multiplier)
        let y = min(maxOffset ?? .infinity, deltaScreenRotation.pitch.radians * multiplier)
        
        return CGSize(width: x, height: y)
    }
    
    func body(content: Content) -> some View {
        content
            .offset(parallaxOffset)
    }
}

public extension View {
    func parallax(multiplier: CGFloat = 50, maxOffset: CGFloat? = nil) -> some View {
        modifier(ParallaxViewModifier(multiplier: multiplier, maxOffset: maxOffset))
    }
}
