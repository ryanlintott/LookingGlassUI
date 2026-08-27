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

    /// `DeviceMotion` has a private initializer, so every test shares the one instance and each starts by putting the state it reads into a known condition rather than assuming a fresh object.
    private var deviceMotion: DeviceMotion { .shared }

    /// `cloneRotationDidChange` drives whether the smoothing animation is suppressed. It must be true only on updates where the clone rotation actually changed.
    func testCloneRotationDidChangeOnlyOnChange() {
        deviceMotion.update(quaternion: Self.towardsPositiveY)
        XCTAssertEqual(deviceMotion.cloneRotation, .identity)

        deviceMotion.update(quaternion: Self.towardsPositiveY)
        XCTAssertFalse(deviceMotion.cloneRotationDidChange, "reported a change when the clone rotation was unchanged")

        deviceMotion.update(quaternion: Self.towardsNegativeY)
        XCTAssertTrue(deviceMotion.cloneRotationDidChange, "did not report a change when the clone rotation changed")
    }

    func testFirstUpdateSetsInitialRotationAndResetClearsIt() {
        deviceMotion.resetInitialRotation()
        XCTAssertNil(deviceMotion.initialDeviceRotation)

        deviceMotion.update(quaternion: Self.towardsPositiveY)
        XCTAssertEqual(deviceMotion.initialDeviceRotation, Self.towardsPositiveY)
        XCTAssertEqual(deviceMotion.deltaRotation, .identity, "delta should be identity while at the initial rotation")

        deviceMotion.update(quaternion: Self.towardsNegativeY)
        XCTAssertEqual(deviceMotion.initialDeviceRotation, Self.towardsPositiveY, "initial rotation should not move with later updates")

        deviceMotion.resetInitialRotation()
        XCTAssertNil(deviceMotion.initialDeviceRotation)
    }

    /// The returned flag is what tells `MotionService` to restart the sensor, so reporting a change that did not happen restarts it on every notification that reads the orientation, including the device being laid flat.
    func testSettingTheInterfaceOrientationReportsOnlyRealChanges() {
        _ = deviceMotion.setInterfaceOrientation(.portrait)

        XCTAssertFalse(deviceMotion.setInterfaceOrientation(.portrait), "an unchanged orientation must not report a change")
        XCTAssertTrue(deviceMotion.setInterfaceOrientation(.landscapeLeft), "a new orientation must report a change")
    }

    /// The rotation is re-zeroed on an orientation change so `deltaRotation` measures from where the device was when the interface settled rather than carrying a ninety degree step across the rotation.
    func testChangingTheInterfaceOrientationResetsTheInitialRotation() {
        _ = deviceMotion.setInterfaceOrientation(.portrait)
        deviceMotion.update(quaternion: Self.towardsPositiveY)
        XCTAssertNotNil(deviceMotion.initialDeviceRotation)

        _ = deviceMotion.setInterfaceOrientation(.landscapeLeft)
        XCTAssertNil(deviceMotion.initialDeviceRotation, "an orientation change must re-zero the rotation")

        deviceMotion.update(quaternion: Self.towardsPositiveY)
        _ = deviceMotion.setInterfaceOrientation(.landscapeLeft)
        XCTAssertNotNil(deviceMotion.initialDeviceRotation, "an unchanged orientation must not re-zero the rotation")
    }
}
