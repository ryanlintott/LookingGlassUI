//
//  FirebladeMath-extension.swift
//  ReflectiveUI
//
//  Created by Ryan Lintott on 2021-05-07.
//

import CoreMotion
import FirebladeMath
import SwiftUI

extension Quat4f {
    init(pitch: Angle? = nil, yaw: Angle? = nil, localRoll: Angle? = nil) {
        let pitch = Quat4f(angle: Float(pitch?.radians ?? .zero), axis: .axisX)
        let yaw = Quat4f(angle: Float(yaw?.radians ?? .zero), axis: .axisZ)
        let localRoll = Quat4f(angle: Float(localRoll?.radians ?? .zero), axis: .axisZ)
        self = yaw * pitch * localRoll
    }
    
    // angle in radians between two quaternions
    func rotationAngle(to q2: Quat4f) -> Float {
        (self.conjugate * q2).rotationAngle
    }
    
    // Screen reference frame
    // With device flat and top facing forward
    // +X is left
    // +Y is forward
    // +Z is down
    // rotations follow right hand rule
    var deviceToScreenReferenceFrame: Quat4f {
        Quat4f(-x, y, -z, w)
    }
    
    // Screen reference frame
    // With device flat and top facing forward
    // +X is right
    // +Y is forward
    // +Z is up
    // rotations follow right hand rule
    var screenToDeviceReferenceFrame: Quat4f {
        deviceToScreenReferenceFrame
    }
}

extension Float {
    var angle: Angle {
        .radians(Double(self))
    }
}

extension Vec3f {
    var cgFloat: (x: CGFloat, y: CGFloat, z: CGFloat) {
        (x: CGFloat(self.x), y: CGFloat(self.y), z: CGFloat(self.z))
    }
}
