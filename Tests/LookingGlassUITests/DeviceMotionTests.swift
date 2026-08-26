//
//  DeviceMotionTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-24.
//

@testable import LookingGlassUI
import SwiftUI
import XCTest

@MainActor
final class DeviceMotionTests: XCTestCase {
    /// Rotations that point the bottom of the device along each horizontal axis.
    ///
    /// The clone rotation is calculated by rotating a vector pointing straight down by the device rotation and checking which horizontal axis it points along.
    private static let towardsPositiveY = Quat(angle: .degrees(90), axis: .xAxis)
    private static let towardsNegativeY = Quat(angle: .degrees(-90), axis: .xAxis)
    private static let towardsNegativeX = Quat(angle: .degrees(90), axis: .yAxis)
    private static let towardsPositiveX = Quat(angle: .degrees(-90), axis: .yAxis)

    func testCloneRotationFlatIsIdentity() {
        XCTAssertEqual(DeviceMotion.cloneRotation(for: .identity), .identity)
    }

    /// A zero angle rotation must be exactly equal to identity or the change check in `update(quaternion:)` would report a change every time the device passed through this quadrant.
    func testZeroAngleRotationEqualsIdentity() {
        XCTAssertEqual(Quat(angle: .zero, axis: .zAxis), .identity)
        XCTAssertEqual(DeviceMotion.cloneRotation(for: Self.towardsPositiveY), .identity)
    }

    func testCloneRotationForEachDirection() {
        XCTAssertEqual(DeviceMotion.cloneRotation(for: Self.towardsPositiveY), .identity)
        XCTAssertEqual(DeviceMotion.cloneRotation(for: Self.towardsNegativeY), Quat(angle: .radians(.pi), axis: .zAxis))
        XCTAssertEqual(DeviceMotion.cloneRotation(for: Self.towardsPositiveX), Quat(angle: .radians(-.pi / 2), axis: .zAxis))
        XCTAssertEqual(DeviceMotion.cloneRotation(for: Self.towardsNegativeX), Quat(angle: .radians(.pi / 2), axis: .zAxis))
    }

    /// `cloneRotationDidChange` drives whether the smoothing animation is suppressed. It must be true only on updates where the clone rotation actually changed.
    func testCloneRotationDidChangeOnlyOnChange() {
        let deviceMotion = DeviceMotion()

        deviceMotion.update(quaternion: Self.towardsPositiveY)
        XCTAssertEqual(deviceMotion.cloneRotation, .identity)

        deviceMotion.update(quaternion: Self.towardsPositiveY)
        XCTAssertFalse(deviceMotion.cloneRotationDidChange, "reported a change when the clone rotation was unchanged")

        deviceMotion.update(quaternion: Self.towardsNegativeY)
        XCTAssertTrue(deviceMotion.cloneRotationDidChange, "did not report a change when the clone rotation changed")
    }

    func testFirstUpdateSetsInitialRotationAndResetClearsIt() {
        let deviceMotion = DeviceMotion()
        XCTAssertNil(deviceMotion.initialDeviceRotation)

        deviceMotion.update(quaternion: Self.towardsPositiveY)
        XCTAssertEqual(deviceMotion.initialDeviceRotation, Self.towardsPositiveY)
        XCTAssertEqual(deviceMotion.deltaRotation, .identity, "delta should be identity while at the initial rotation")

        deviceMotion.update(quaternion: Self.towardsNegativeY)
        XCTAssertEqual(deviceMotion.initialDeviceRotation, Self.towardsPositiveY, "initial rotation should not move with later updates")

        deviceMotion.resetInitialRotation()
        XCTAssertNil(deviceMotion.initialDeviceRotation)
    }
}
