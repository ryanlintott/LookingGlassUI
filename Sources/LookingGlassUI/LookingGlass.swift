//
//  LookingGlass.swift
//  
//
//  Created by Ryan Lintott on 2021-05-14.
//

import CoreMotion
import FirebladeMath
import SwiftUI

@available(iOS 14, *)
public struct LookingGlass<Content: View>: View {
    @EnvironmentObject var motionManager: MotionManager

    let type: DeviceRotationEffectType
    let distance: CGFloat?
    let perspective: CGFloat?
    let offsetRotation: Quat4f?
    let isShowingInFourDirections: Bool?
    let content: Content
    
    public init(
        _ type: DeviceRotationEffectType,
        distance: CGFloat? = nil,
        perspective: CGFloat? = nil,
        offsetRotation: Quat4f? = nil,
        isShowingInFourDirections: Bool? = nil,
        content: () -> Content
    ) {
        self.type = type
        self.distance = distance
        self.perspective = perspective
        self.offsetRotation = offsetRotation
        self.isShowingInFourDirections = isShowingInFourDirections
        self.content = content()
    }
    
    public init(_ type: DeviceRotationEffectType, distance: CGFloat, perspective: CGFloat? = nil, pitch: Angle? = nil, roll: Angle? = nil, yaw: Angle? = nil, isShowingInFourDirections: Bool? = nil, content: () -> Content) {
        self.init(type, distance: distance, perspective: perspective, offsetRotation: Quat4f(pitch: pitch, yaw: yaw, roll: roll), isShowingInFourDirections: isShowingInFourDirections, content: content)
    }
    
    public var body: some View {
        if motionManager.isDetectingMotion {
            GeometryReader { proxy in
                content
                    .deviceRotationEffect(type, distance: distance, perspective: perspective, offsetRotation: offsetRotation, isShowingInFourDirections: isShowingInFourDirections)
                    .frame(width: motionManager.interfaceSize.width, height: motionManager.interfaceSize.height)
                    .offset(x: (proxy.size.width / 2) - proxy.frame(in: .global).midX, y: (proxy.size.height / 2) - proxy.frame(in: .global).midY)
            }
        } else {
            Color.clear
        }
    }
}
