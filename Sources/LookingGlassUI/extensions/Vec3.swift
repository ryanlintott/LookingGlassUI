//
//  Vec3.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2022-08-31.
//

import Foundation
import func simd.simd_normalize
import func simd.simd_length

public typealias Vec3 = SIMD3<Double>

public extension Vec3 {
    /// A vector representation of the x axis.
    static let xAxis: Vec3 = [1, 0, 0]
    /// A vector representation of the y axis.
    static let yAxis: Vec3 = [0, 1, 0]
    /// A vector representation of the z axis.
    static let zAxis: Vec3 = [0, 0, 1]
    
    /// This vector represented as a tuple of CGFloat (used in SwiftUI rotation3dEffect)
    var cgFloat: (x: CGFloat, y: CGFloat, z: CGFloat) {
        (x: x, y: y, z: z)
    }
    
    /// A version of this vector with length 1.
    var normalized: Self {
        simd_normalize(self)
    }
}
