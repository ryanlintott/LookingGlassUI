//
//  Quat+CoreMotion.swift
//  
//
//  Created by Ryan Lintott on 2024-06-14.
//

import CoreMotion

public extension Quat {
    /// Creates a quaternion from a Core Motion quaternion.
    init(_ q: CMQuaternion) {
        self.init(q.x, q.y, q.z, q.w)
    }
}
