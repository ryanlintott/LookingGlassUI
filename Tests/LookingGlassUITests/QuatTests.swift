//
//  QuatTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2022-09-01.
//

@testable import LookingGlassUI
import simd.quaternion
import SwiftUI
import XCTest

final class QuatTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testIdentity() throws {
        // when
        let quat = Quat.identity
        
        // then
        XCTAssertEqual(quat.x, 0)
        XCTAssertEqual(quat.y, 0)
        XCTAssertEqual(quat.z, 0)
        XCTAssertEqual(quat.w, 1)
    }
    
    func testSimdXAxisAngle() throws {
        // when
        let angle = Angle.degrees(30)
        let quat = Quat(angle: angle, axis: .xAxis)
        
        // then
        XCTAssertEqual(angle, quat.angle)
    }
    
    func testSimdYAxisAngle() throws {
        // when
        let angle = Angle.degrees(30)
        let quat = Quat(angle: angle, axis: .yAxis)
        
        // then
        XCTAssertEqual(angle, quat.angle)
    }
    
    func testSimdZAxisAngle() throws {
        // when
        let angle = Angle.degrees(30)
        let quat = Quat(angle: angle, axis: .zAxis)
        
        // then
        XCTAssertEqual(angle, quat.angle)
    }
    
    func testSimdArbitraryNormalizedAxisAngleNormalized() throws {
        for _ in 1...100 {
            // given
            let angle = Angle.degrees(30)
            let axis = Vec3(x: .random(in: -1...1), y: .random(in: -1...1), z: .random(in: -1...1)).normalized
            
            // when
            let quat = Quat(angle: angle, axis: axis)
            
            // then
            XCTAssertEqual(axis.x, quat.axis.x, accuracy: 1e-7)
            XCTAssertEqual(axis.y, quat.axis.y, accuracy: 1e-7)
            XCTAssertEqual(axis.z, quat.axis.z, accuracy: 1e-7)
            XCTAssertEqual(angle.radians, quat.angle.radians, accuracy: 1e-7)
        }
    }

    /// Rotations that point the bottom of the device along each horizontal axis.
    ///
    /// The clone rotation is calculated by rotating a vector pointing straight down by the device rotation and checking which horizontal axis it points along.
    private static let towardsPositiveY = Quat(angle: .degrees(90), axis: .xAxis)
    private static let towardsNegativeY = Quat(angle: .degrees(-90), axis: .xAxis)
    private static let towardsNegativeX = Quat(angle: .degrees(90), axis: .yAxis)
    private static let towardsPositiveX = Quat(angle: .degrees(-90), axis: .yAxis)

    func testCloneRotationFlatIsIdentity() {
        XCTAssertEqual(Quat.identity.cloneRotation, .identity)
    }

    /// A zero angle rotation must be exactly equal to identity or the change check in `DeviceMotion.update(quaternion:)` would report a change every time the device passed through this quadrant.
    func testZeroAngleRotationEqualsIdentity() {
        XCTAssertEqual(Quat(angle: .zero, axis: .zAxis), .identity)
        XCTAssertEqual(Self.towardsPositiveY.cloneRotation, .identity)
    }

    func testCloneRotationForEachDirection() {
        XCTAssertEqual(Self.towardsPositiveY.cloneRotation, .identity)
        XCTAssertEqual(Self.towardsNegativeY.cloneRotation, Quat(angle: .radians(.pi), axis: .zAxis))
        XCTAssertEqual(Self.towardsPositiveX.cloneRotation, Quat(angle: .radians(-.pi / 2), axis: .zAxis))
        XCTAssertEqual(Self.towardsNegativeX.cloneRotation, Quat(angle: .radians(.pi / 2), axis: .zAxis))
    }
}
