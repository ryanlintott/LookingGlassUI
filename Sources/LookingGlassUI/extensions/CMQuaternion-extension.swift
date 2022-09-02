//
//  CMQuaternion-extension.swift
//  ReflectiveUI
//
//  Created by Ryan Lintott on 2021-05-11.
//

import CoreMotion

extension CMQuaternion: Equatable {
    public static func == (lhs: CMQuaternion, rhs: CMQuaternion) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w
    }
    
    /// Quat version of Core Motion quaternion
    public var quat: Quat {
        .init(x, y, z, w)
    }
}
