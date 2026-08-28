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

    /// Lying flat needs no clone rotation, and it must be exactly identity or the change check in `update(quaternion:)` would report a change every time the device passed through that quadrant.
    func testCloneRotationFlatIsIdentity() {
        deviceMotion.update(quaternion: .identity)
        XCTAssertEqual(deviceMotion.cloneRotation, .identity)

        deviceMotion.update(quaternion: Self.towardsPositiveY)
        XCTAssertEqual(deviceMotion.cloneRotation, .identity)
    }

    func testCloneRotationForEachDirection() {
        deviceMotion.update(quaternion: Self.towardsPositiveY)
        XCTAssertEqual(deviceMotion.cloneRotation, .identity)

        deviceMotion.update(quaternion: Self.towardsNegativeY)
        XCTAssertEqual(deviceMotion.cloneRotation, Quat(angle: .radians(.pi), axis: .zAxis))

        deviceMotion.update(quaternion: Self.towardsPositiveX)
        XCTAssertEqual(deviceMotion.cloneRotation, Quat(angle: .radians(-.pi / 2), axis: .zAxis))

        deviceMotion.update(quaternion: Self.towardsNegativeX)
        XCTAssertEqual(deviceMotion.cloneRotation, Quat(angle: .radians(.pi / 2), axis: .zAxis))
    }

    func testFirstUpdateSetsInitialRotationAndResetClearsIt() {
        deviceMotion.resetInitialRotation()
        XCTAssertNil(deviceMotion.initialDeviceRotation)

        deviceMotion.update(quaternion: Self.towardsPositiveY)
        XCTAssertEqual(deviceMotion.initialDeviceRotation, Self.towardsPositiveY)

        deviceMotion.update(quaternion: Self.towardsNegativeY)
        XCTAssertEqual(deviceMotion.initialDeviceRotation, Self.towardsPositiveY, "initial rotation should not move with later updates")

        deviceMotion.resetInitialRotation()
        XCTAssertNil(deviceMotion.initialDeviceRotation)
    }

    /// An attitude that is not the zero position, so a delta measured about the wrong frame shows up even in portrait.
    private static let restingAttitude = Quat(angle: .degrees(35), axis: .zAxis)

    /// Settles the device at ``restingAttitude`` in `orientation`, then tilts it by `tilt` about the screen's own axes.
    ///
    /// Conjugating by the interface rotation is what makes `tilt` mean the same physical movement of the screen in every orientation, which is the thing the interface-aligned delta has to recover.
    private func settle(in orientation: UIInterfaceOrientation, thenTiltBy tilt: Quat) {
        _ = deviceMotion.setInterfaceOrientation(orientation)
        deviceMotion.resetInitialRotation()

        let interfaceRotation = deviceMotion.interfaceRotation
        deviceMotion.update(quaternion: Self.restingAttitude)
        deviceMotion.update(quaternion: Self.restingAttitude * interfaceRotation * tilt * interfaceRotation.inverse)
    }

    /// The same physical tilt of the screen must produce the same rotation in every interface orientation. Measuring it about the reference frame instead put it around ninety degrees out in landscape and a hundred and eighty in upside down portrait.
    func testInterfaceAlignedDeltaIsTheSameInEveryInterfaceOrientation() {
        let tilt = Quat(angle: .degrees(20), axis: .xAxis)

        for orientation in [UIInterfaceOrientation.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown] {
            settle(in: orientation, thenTiltBy: tilt)

            let error = (deviceMotion.deltaRotation.inverse * tilt).angle
            XCTAssertEqual(error.degrees, 0, accuracy: 1e-9, "delta was measured about the wrong axes in \(orientation)")
        }
    }

    /// `parallax` reads the yaw and pitch of this rotation in the screen reference frame, so a tilt about one screen axis must not leak into the other. In landscape it did, and the view moved along the wrong axis.
    func testScreenRotationOfATiltMatchesPortraitInEveryOrientation() {
        let tilt = Quat(angle: .degrees(20), axis: .xAxis)

        settle(in: .portrait, thenTiltBy: tilt)
        let portrait = deviceMotion.deltaRotation.deviceToScreenReferenceFrame

        XCTAssertEqual(portrait.yaw.degrees, 0, accuracy: 1e-9, "a tilt about one screen axis must not appear on the other")

        for orientation in [UIInterfaceOrientation.landscapeLeft, .landscapeRight, .portraitUpsideDown] {
            settle(in: orientation, thenTiltBy: tilt)
            let rotation = deviceMotion.deltaRotation.deviceToScreenReferenceFrame

            XCTAssertEqual(rotation.pitch.degrees, portrait.pitch.degrees, accuracy: 1e-9, "pitch differed from portrait in \(orientation)")
            XCTAssertEqual(rotation.yaw.degrees, portrait.yaw.degrees, accuracy: 1e-9, "yaw differed from portrait in \(orientation)")
        }
    }

    /// Both deltas measure from the initial rotation, so both have nothing to measure until a sample has arrived.
    func testDeltasAreIdentityBeforeTheFirstUpdate() {
        deviceMotion.resetInitialRotation()
        
        XCTAssertEqual(deviceMotion.deltaRotation, .identity)
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
