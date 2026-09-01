//
//  Vec3Tests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-28.
//

@testable import LookingGlassUI
import simd
import XCTest

final class Vec3Tests: XCTestCase {
    /// The limit is a distance, not a bound on each axis. Clamping x and y separately let a diagonal reach the limit on both at once and travel `maxLength * sqrt(2)`, tracing a square instead of a circle. `parallax` uses this, so that square was visible as a view that moved further into the corners than it did straight up.
    func testLimitingIsCircularRatherThanSquare() {
        let diagonal = Vec3(x: 100, y: 100, z: 0)

        let limited = diagonal.limited(to: 10)

        XCTAssertEqual(simd_length(limited), 10, accuracy: 1e-9)
    }

    /// Only the length changes. A limit that also turned the vector would send the parallax offset off in a direction the device was never tilted.
    func testLimitingKeepsTheDirection() {
        let vector = Vec3(x: 3, y: -4, z: 12)

        let limited = vector.limited(to: 1)

        XCTAssertEqual(limited.normalized.x, vector.normalized.x, accuracy: 1e-9)
        XCTAssertEqual(limited.normalized.y, vector.normalized.y, accuracy: 1e-9)
        XCTAssertEqual(limited.normalized.z, vector.normalized.z, accuracy: 1e-9)
    }

    /// A vector already inside the limit has to come back untouched rather than scaled up to meet it.
    func testLimitingLeavesShorterVectorsAlone() {
        let vector = Vec3(x: 1, y: 2, z: 2)

        XCTAssertEqual(vector.limited(to: 100), vector)
    }

    /// `parallax` passes infinity when no maximum was given, which has to mean no limit rather than an unusable result.
    func testAnInfiniteLimitChangesNothing() {
        let vector = Vec3(x: 3, y: -4, z: 12)

        XCTAssertEqual(vector.limited(to: .infinity), vector)
    }

    /// The zero vector has no direction to preserve, and scaling it would divide by its own length. It appears whenever the device is exactly at its settled rotation, which is every time motion updates start.
    func testLimitingTheZeroVectorDoesNotProduceNotANumber() {
        let limited = Vec3.zero.limited(to: 10)

        XCTAssertEqual(limited, .zero)
    }

    /// A negative limit is still a distance, so it caps at its magnitude rather than flipping the vector through the origin.
    func testANegativeLimitCapsAtItsMagnitude() {
        let vector = Vec3(x: 100, y: 0, z: 0)

        let limited = vector.limited(to: -10)

        XCTAssertEqual(limited, Vec3(x: 10, y: 0, z: 0))
    }
}
