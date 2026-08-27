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
    /// Rotations that point the bottom of the device along opposite horizontal axes, so their clone rotations differ.
    private static let towardsPositiveY = Quat(angle: .degrees(90), axis: .xAxis)
    private static let towardsNegativeY = Quat(angle: .degrees(-90), axis: .xAxis)

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
