//
//  CMQuaternion-extension.swift
//  ReflectiveUI
//
//  Created by Ryan Lintott on 2021-05-11.
//

import CoreMotion
import FirebladeMath

extension CMQuaternion: Equatable {
    public static func == (lhs: CMQuaternion, rhs: CMQuaternion) -> Bool {
        lhs.x == rhs.x && lhs.y == rhs.y && lhs.z == rhs.z && lhs.w == rhs.w
    }
    
    /// Quat4f version of Core Motion quaternion
    public var quat4f: Quat4f {
        Quat4f(Float(self.x), Float(self.y), Float(self.z), Float(self.w))
    }
}
