//
//  QuatTests.swift
//
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
        XCTAssertEqual(angle, quat.rotationAngle)
    }
    
    func testSimdYAxisAngle() throws {
        // when
        let angle = Angle.degrees(30)
        let quat = Quat(angle: angle, axis: .yAxis)
        
        // then
        XCTAssertEqual(angle, quat.rotationAngle)
    }
    
    func testSimdZAxisAngle() throws {
        // when
        let angle = Angle.degrees(30)
        let quat = Quat(angle: angle, axis: .zAxis)
        
        // then
        XCTAssertEqual(angle, quat.rotationAngle)
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
            XCTAssertEqual(angle.radians, quat.rotationAngle.radians, accuracy: 1e-7)
        }
    }
}
