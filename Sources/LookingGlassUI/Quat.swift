//
//  Quat.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2022-08-31.
//

import simd.quaternion
import SwiftUI

/// A wrapper for simd.quaternion with handy extensions.
public struct Quat: Equatable, Hashable, Sendable {
    /// The data for this quaternion stored as a simd quaternion.
    public var simd: simd_quatd
    
    /// Creats a quaternion from a simd quaternion
    /// - Parameter simd: Quaternion data to store.
    public init(_ simd: simd_quatd) {
        self.simd = simd
    }
}

public extension Quat {
    /// Creates a quaternion from components.
    init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        simd = .init(ix: x, iy: y, iz: z, r: w)
    }
    
    var x: Double {
        get { simd.imag.x }
        set { simd.imag.x = newValue }
    }
    
    var y: Double {
        get { simd.imag.y }
        set { simd.imag.y = newValue }
    }
    
    var z: Double {
        get { simd.imag.z }
        set { simd.imag.z = newValue }
    }
    
    var w: Double {
        get { simd.real }
        set { simd.real = newValue }
    }
    
    /// The identity quaternion.
    static let identity = Self(0, 0, 0, 1)
    
    /// The axis vector when this quaternion is represented as an axis and a rotation.
    var axis: Vec3 {
        .init(simd.axis)
    }
    
    /// The angle of rotation when this quaternion is represented as an axis and a rotation.
    var angle: Angle {
        .radians(simd.angle)
    }
    
    @available(*, deprecated, renamed: "angle")
    var rotationAngle: Angle {
        angle
    }
    
    /// The complex conjugate of this quaternion.
    var conjugate: Self {
        .init(simd.conjugate)
    }
    
    /// A normalized version of this quaternion.
    var normalized: Self {
        .init(simd.normalized)
    }
    
    /// The inverse of this quaternion.
    var inverse: Self {
        .init(simd.inverse)
    }
    
    /// Creates a quaternion from a rotation angle and axis vector.
    /// - Parameters:
    ///   - angle: Angle of rotation.
    ///   - axis: Axis for the rotation.
    init(angle: Angle, axis: Vec3) {
        simd = simd_quaternion(angle.radians, axis)
    }
    
    /// Multiplication for two quaternions (order matters)
    static func * (lhs: Self, rhs: Self) -> Self {
        .init(simd_mul(lhs.simd, rhs.simd))
    }
    
    /// A quaternion created from pitch, yaw, and local roll angles.
    /// - Parameters:
    ///   - pitch: rotation around X axis. Default is zero.
    ///   - yaw: rotation around Z axis. Default is zero.
    ///   - localRoll: rotation around local Z axis. Default is zero.
    init(pitch: Angle? = nil, yaw: Angle? = nil, localRoll: Angle? = nil) {
        let pitch = Self(angle: pitch ?? .zero, axis: .xAxis)
        let yaw = Self(angle: yaw ?? .zero, axis: .zAxis)
        let localRoll = Self(angle: localRoll ?? .zero, axis: .zAxis)
        self = yaw * pitch * localRoll
    }
    
    /// The yaw angle (rotation around the Y axis) between -180 to 180 degrees.
    @inlinable var yaw: Angle {
        /// https://github.com/OGRECave/ogre/blob/master/OgreMain/src/OgreQuaternion.cpp#L508
        .radians(asin(-2 * (x * z - w * y)))
    }

    /// The pitch angle (rotation around the X zxis) between -180 to 180 degrees.
    @inlinable var pitch: Angle {
        /// https://github.com/OGRECave/ogre/blob/master/OgreMain/src/OgreQuaternion.cpp#L484
        .radians(atan2(2.0 * (y * z + w * x), w * w - x * x - y * y + z * z))
    }

    /// The roll angle (rotation around the Z axis) between -180 to 180 degrees.
    @inlinable var roll: Angle {
        /// https://github.com/OGRECave/ogre/blob/master/OgreMain/src/OgreQuaternion.cpp#L459
        .radians(atan2(2.0 * (x * y + w * z), w * w + x * x - y * y - z * z))
    }
    
    /// Returns the angle between two quaternions
    /// - Parameter q2: Second quaternion.
    /// - Returns: Angle in radians between two quaternions.
    func rotationAngle(to q2: Self) -> Angle {
        (conjugate * q2).angle
    }

    /// Returns a rotation part way between this one and another, turning the short way around.
    ///
    /// The angle between the result and this rotation is `amount` of the angle between the two, so moving repeatedly by a fixed fraction closes the gap exponentially rather than at a steady rate.
    ///
    /// - Parameters:
    ///   - other: Rotation to move towards.
    ///   - amount: How far to move, where zero stays here and one arrives at `other`.
    /// - Returns: The rotation that far between the two.
    func slerp(to other: Self, amount: Double) -> Self {
        .init(simd_slerp(simd, other.simd, amount))
    }
    
    /// Transformation from device reference frame to screen reference frame.
    ///
    /// Device reference frame:
    /// With device flat and top facing forward
    /// +X is left
    /// +Y is forward
    /// +Z is down
    /// rotations follow right hand rule
    var deviceToScreenReferenceFrame: Self {
        Self(-x, y, -z, w)
    }
    
    /// Transformation from screen reference frame to device reference frame.
    ///
    /// Screen reference frame
    /// With device flat and top facing forward
    /// +X is right
    /// +Y is forward
    /// +Z is up
    /// rotations follow right hand rule
    var screenToDeviceReferenceFrame: Self {
        deviceToScreenReferenceFrame
    }
    
    /// Returns a vector rotated by this quaternion.
    ///
    /// - Parameters:
    ///   - vector: Vector to be rotated.
    /// - Returns: The rotated vector.
    func rotating(_ vector: Vec3) -> Vec3 {
        simd_act(simd.normalized, vector)
    }
    
    /// Where a point resting `distance` in front of the centre of the screen appears to sit once the device has turned by this rotation.
    ///
    /// This rotation describes how the device turned. A point resting in front of the screen stays where it is while the screen turns beneath it, so it travels across the screen by the opposite rotation. That inverse is what puts a positive `distance` in front of the screen rather than behind it, where content moves the other way.
    ///
    /// The point is carried around and then flattened onto the screen, so the offset follows the sine of the angle rather than the angle itself. It reaches `distance` when the point has come level with the screen and falls away again as the device keeps turning past it, rather than growing without bound and leaving `maxOffset` to do all the work.
    ///
    /// Turning in the plane of the screen leaves a point on the screen's own axis exactly where it was, so a roll produces no offset at all without having to be excluded.
    ///
    /// - Parameters:
    ///   - distance: How far in front of the screen the point rests, in points. Also the furthest the offset can reach.
    ///   - maxOffset: Limits the offset to this distance from the resting position, in any direction.
    /// - Returns: The offset of the point from the centre of the screen.
    func parallaxOffset(distance: CGFloat, maxOffset: CGFloat?) -> CGSize {
        let point = inverse.rotating(Vec3(x: 0, y: 0, z: distance))
        let offset = Vec3(x: point.x, y: point.y, z: 0).limited(to: maxOffset ?? .infinity)

        return CGSize(width: offset.x, height: offset.y)
    }
}
