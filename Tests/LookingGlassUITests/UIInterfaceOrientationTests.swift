//
//  UIInterfaceOrientationTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-26.
//

@testable import LookingGlassUI
import SwiftUI
import XCTest

@MainActor
final class UIInterfaceOrientationTests: XCTestCase {
    // MARK: - Rotation

    /// The two landscape orientations turn the interface opposite ways, and this is the pair most easily copied from one another. When they matched, content was a hundred and eighty degrees out in one of the two.
    func testTheLandscapeRotationsAreOppositeQuarterTurns() throws {
        let left = try XCTUnwrap(UIInterfaceOrientation.landscapeLeft.rotation)
        let right = try XCTUnwrap(UIInterfaceOrientation.landscapeRight.rotation)

        XCTAssertEqual(left.angle.degrees, 90, accuracy: 1e-9)
        XCTAssertEqual(right.angle.degrees, 90, accuracy: 1e-9)
        assertSameRotation(left * right, .identity, "the landscape rotations must undo each other")
    }

    /// Turning the interface upside down twice returns it the way it started.
    func testTheUpsideDownRotationIsItsOwnInverse() throws {
        let upsideDown = try XCTUnwrap(UIInterfaceOrientation.portraitUpsideDown.rotation)

        assertSameRotation(upsideDown * upsideDown, .identity)
    }

    /// The interface only ever turns in the plane of the screen. A rotation with any component about another axis would tip content out of that plane, which no interface orientation does.
    func testEveryRotationTurnsAboutTheScreenNormalAlone() throws {
        for orientation in UIInterfaceOrientation.allShowable where orientation != .portrait {
            let rotation = try XCTUnwrap(orientation.rotation)

            XCTAssertEqual(rotation.axis.x, 0, accuracy: 1e-9, "\(orientation.testName) turned about x")
            XCTAssertEqual(rotation.axis.y, 0, accuracy: 1e-9, "\(orientation.testName) turned about y")
            XCTAssertEqual(abs(rotation.axis.z), 1, accuracy: 1e-9, "\(orientation.testName) did not turn about z")
        }
    }

    /// Four orientations need four different rotations. Two that matched would leave content correct in one and turned in the other, which is exactly how the landscape bug looked.
    func testEveryOrientationHasItsOwnRotation() throws {
        let rotations = try UIInterfaceOrientation.allShowable.map { try XCTUnwrap($0.rotation) }

        for (first, second) in rotations.enumerated().flatMap({ index, rotation in
            rotations[(index + 1)...].map { (rotation, $0) }
        }) {
            XCTAssertGreaterThan(first.rotationAngle(to: second).degrees, 1, "two orientations share a rotation")
        }
    }

    /// An unknown orientation says nothing about which way the interface is facing, so it must report no rotation rather than guessing at portrait and leaving content turned in any orientation but that one.
    func testUnknownOrientationHasNoRotation() {
        XCTAssertNil(UIInterfaceOrientation.unknown.rotation)
    }
}
