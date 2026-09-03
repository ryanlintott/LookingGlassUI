//
//  Vec3.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2022-08-31.
//

import Foundation
import func simd.simd_normalize
import func simd.simd_length

/// A wrapper for a three dimensional vector of `Double` with handy extensions.
///
/// The vector is stored in ``simd``, which is public, so anything `SIMD3<Double>` can do is still reachable through it.
public struct Vec3: Equatable, Hashable, Sendable {
    /// The data for this vector stored as a simd vector.
    public var simd: SIMD3<Double>

    /// Creates a vector from a simd vector.
    /// - Parameter simd: Vector data to store.
    public init(_ simd: SIMD3<Double>) {
        self.simd = simd
    }
}

public extension Vec3 {
    /// Creates a vector from components.
    init(x: Double, y: Double, z: Double) {
        self.init(SIMD3(x: x, y: y, z: z))
    }

    var x: Double {
        get { simd.x }
        set { simd.x = newValue }
    }

    var y: Double {
        get { simd.y }
        set { simd.y = newValue }
    }

    var z: Double {
        get { simd.z }
        set { simd.z = newValue }
    }

    /// A vector with no length.
    static let zero = Self(x: 0, y: 0, z: 0)
    /// A vector representation of the x axis.
    static let xAxis = Self(x: 1, y: 0, z: 0)
    /// A vector representation of the y axis.
    static let yAxis = Self(x: 0, y: 1, z: 0)
    /// A vector representation of the z axis.
    static let zAxis = Self(x: 0, y: 0, z: 1)

    /// This vector represented as a tuple of `CGFloat` (used in SwiftUI `rotation3DEffect()`)
    var cgFloat: (x: CGFloat, y: CGFloat, z: CGFloat) {
        (x: x, y: y, z: z)
    }

    /// A version of this vector with length 1.
    var normalized: Self {
        Self(simd_normalize(simd))
    }

    /// This vector, shortened to the absolute value of `maxLength` if it's longer, with its direction unchanged.
    internal func limited(to maxLength: Double) -> Self {
        let length = simd_length(simd)
        guard length > abs(maxLength) else { return self }
        return Self(simd * (abs(maxLength) / length))
    }
}
