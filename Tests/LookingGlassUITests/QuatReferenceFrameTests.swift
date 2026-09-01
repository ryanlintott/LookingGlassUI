//
//  QuatReferenceFrameTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-28.
//

@testable import LookingGlassUI
import SwiftUI
import XCTest

/// Core Motion and SwiftUI disagree about which way two of the three axes point, and every effect in this package ends by crossing that gap. These cover the crossing itself, separately from the rotations that use it.
final class QuatReferenceFrameTests: XCTestCase {
    private static let arbitrary = Quat(angle: .degrees(76), axis: Vec3(x: 0.357, y: -0.369, z: 0.858).normalized)

    /// `screenToDeviceReferenceFrame` is the same operation as `deviceToScreenReferenceFrame`, which is only correct because the conversion is its own inverse. If it ever stops being one, the two names have to start doing different things.
    func testConvertingBetweenReferenceFramesIsItsOwnInverse() {
        assertSameRotation(Self.arbitrary.deviceToScreenReferenceFrame.screenToDeviceReferenceFrame, Self.arbitrary)
    }

    /// The conversion re-describes a rotation about different axes. It must not change how far the rotation actually turns, or content would arrive at the wrong angle rather than merely about the wrong axis.
    func testConvertingBetweenReferenceFramesPreservesTheAngleTurned() {
        XCTAssertEqual(
            Self.arbitrary.deviceToScreenReferenceFrame.angle.degrees,
            Self.arbitrary.angle.degrees,
            accuracy: 1e-9
        )
    }

    /// `deltaRotation` and `realWorldOrientation` both build a chain of rotations in the device frame and convert once at the end. That is only equivalent to converting each term because the conversion distributes over composition, and it distributes in order rather than reversing it.
    ///
    /// If this fails, every composite rotation in the package is silently wrong in a way that looks right in portrait.
    func testConvertingBetweenReferenceFramesDistributesOverComposition() {
        let a = Quat(pitch: .degrees(37), yaw: .degrees(-12), localRoll: .degrees(80))
        let b = Quat(angle: .degrees(51), axis: Vec3(x: 0.3, y: -0.5, z: 0.81).normalized)

        assertSameRotation(
            (a * b).deviceToScreenReferenceFrame,
            a.deviceToScreenReferenceFrame * b.deviceToScreenReferenceFrame,
            "converting a composition must match converting each term in the same order"
        )
    }

    /// The two frames agree on which way the device's own top points and disagree about the other two axes, so a turn about x or z comes back as a turn the other way and a turn about y comes back untouched.
    func testConvertingBetweenReferenceFramesReversesTheXAndZAxesOnly() {
        let angle = Angle.degrees(30)

        assertSameRotation(
            Quat(angle: angle, axis: .xAxis).deviceToScreenReferenceFrame,
            Quat(angle: -angle, axis: .xAxis),
            "a turn about x must come back reversed"
        )
        assertSameRotation(
            Quat(angle: angle, axis: .zAxis).deviceToScreenReferenceFrame,
            Quat(angle: -angle, axis: .zAxis),
            "a turn about z must come back reversed"
        )
        assertSameRotation(
            Quat(angle: angle, axis: .yAxis).deviceToScreenReferenceFrame,
            Quat(angle: angle, axis: .yAxis),
            "a turn about y must come back unchanged"
        )
    }

    /// `Quat(pitch:yaw:localRoll:)` names its second argument `yaw` and turns about the z axis, while the `yaw` property reads a turn about the y axis and the `roll` property reads the one about z. Anything built with the initialiser and read back through the properties therefore comes out under a different name than it went in under.
    ///
    /// `parallax` reads `pitch` and `yaw`, so this is the difference between a view that drifts sideways and one that doesn't. Pinned here so the mismatch can't be quietly resolved in one place only.
    func testTheInitialiserYawIsReadBackAsRoll() {
        let yawed = Quat(pitch: .zero, yaw: .degrees(30), localRoll: .zero)

        XCTAssertEqual(yawed.roll.degrees, 30, accuracy: 1e-9, "the initialiser's yaw turns about z, which the properties call roll")
        XCTAssertEqual(yawed.yaw.degrees, 0, accuracy: 1e-9, "the property yaw reads a turn about y, which was never applied")

        /// Pitch is the one argument that does come back under its own name.
        let pitched = Quat(pitch: .degrees(30), yaw: .zero, localRoll: .zero)
        XCTAssertEqual(pitched.pitch.degrees, 30, accuracy: 1e-9)
    }

    /// With no pitch between them, the yaw and local roll arguments turn about the same axis and are indistinguishable in the result. It's pitch that separates them, and that's the whole reason the third argument is a *local* roll.
    func testYawAndLocalRollAreOneRotationUntilThereIsPitchBetweenThem() {
        assertSameRotation(
            Quat(pitch: .zero, yaw: .degrees(30), localRoll: .zero),
            Quat(pitch: .zero, yaw: .zero, localRoll: .degrees(30)),
            "without pitch these are the same turn about z"
        )

        let yawFirst = Quat(pitch: .degrees(50), yaw: .degrees(30), localRoll: .zero)
        let rollLast = Quat(pitch: .degrees(50), yaw: .zero, localRoll: .degrees(30))
        XCTAssertGreaterThan(
            yawFirst.rotationAngle(to: rollLast).degrees,
            1,
            "with pitch between them, yawing before and rolling after must differ"
        )
    }
}
