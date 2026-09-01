//
//  ParallaxOffsetTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-31.
//

@testable import LookingGlassUI
import SwiftUI
import XCTest

/// `parallax` treats its content as a point resting a little way in front of the screen and shows where that point lands as the device turns. These cover the projection itself, separately from the rotation that feeds it.
final class ParallaxOffsetTests: XCTestCase {
    private static let distance: CGFloat = 50

    private func offset(_ rotation: Quat, maxOffset: CGFloat? = nil) -> CGSize {
        rotation.parallaxOffset(distance: Self.distance, maxOffset: maxOffset)
    }

    /// Turning the device in the plane of its own screen moves nothing towards or away from the viewer. A point on the axis being turned about is left exactly where it was, so this is exact rather than merely small.
    func testTurningInThePlaneOfTheScreenProducesNoOffset() {
        for degrees in [30.0, 90.0, 180.0] {
            let result = offset(Quat(angle: .degrees(degrees), axis: .zAxis))

            XCTAssertEqual(result.width, 0, accuracy: 1e-9, "a \(degrees) degree roll moved the view sideways")
            XCTAssertEqual(result.height, 0, accuracy: 1e-9, "a \(degrees) degree roll moved the view vertically")
        }
    }

    /// Each of the two turns the effect responds to has to move the view along one axis only. When they bled into each other the view drifted diagonally on a straight tilt.
    func testEachTurnMovesTheViewAlongOneAxisOnly() {
        let tipped = offset(Quat(angle: .degrees(20), axis: .xAxis))
        XCTAssertEqual(tipped.width, 0, accuracy: 1e-9, "tipping the top of the screen must not move the view sideways")
        XCTAssertNotEqual(tipped.height, 0, accuracy: 1e-9)

        let turned = offset(Quat(angle: .degrees(20), axis: .yAxis))
        XCTAssertEqual(turned.height, 0, accuracy: 1e-9, "tipping the side of the screen must not move the view vertically")
        XCTAssertNotEqual(turned.width, 0, accuracy: 1e-9)
    }

    /// The direction the view travels, measured on a device. It used to run the other way on both axes, which rendered a positive `distance` as though the content sat behind the glass rather than in front of it. Pinned by sign so it cannot quietly flip back.
    ///
    /// The content stays where it is while the screen turns beneath it, so it travels against the turn. Tilting the top of the screen away from the viewer, which reads as a positive pitch, moves the view down the screen.
    func testTheDirectionTheViewTravels() {
        let pitched = offset(Quat(angle: .degrees(20), axis: .xAxis))
        XCTAssertGreaterThan(pitched.height, 0, "tilting the top of the screen away must move the view down the screen")

        let turned = offset(Quat(angle: .degrees(20), axis: .yAxis))
        XCTAssertLessThan(turned.width, 0, "turning about the screen's vertical axis must move the view against the turn")
    }

    /// A negative distance rests the content behind the screen, where it moves the opposite way. It has to be an exact mirror of the same distance in front, or the two sides of the glass would behave differently.
    func testANegativeDistanceMovesTheViewTheOtherWay() {
        for axis in [Vec3.xAxis, .yAxis] {
            let rotation = Quat(angle: .degrees(25), axis: axis)
            let inFront = offset(rotation)
            let behind = rotation.parallaxOffset(distance: -Self.distance, maxOffset: nil)

            XCTAssertEqual(behind.width, -inFront.width, accuracy: 1e-9)
            XCTAssertEqual(behind.height, -inFront.height, accuracy: 1e-9)
        }
    }

    /// The point can't be further from the centre of the screen than it is from the screen, so the offset peaks once it comes level and falls away as the device keeps turning past it. The angle in radians instead grew forever, which left `maxOffset` doing the work of the geometry.
    func testTheOffsetPeaksWhenThePointComesLevelWithTheScreen() {
        XCTAssertEqual(offset(Quat(angle: .degrees(90), axis: .xAxis)).height, Self.distance, accuracy: 1e-9)

        let past = offset(Quat(angle: .degrees(150), axis: .xAxis)).height
        let short = offset(Quat(angle: .degrees(30), axis: .xAxis)).height
        XCTAssertEqual(past, short, accuracy: 1e-9, "turning past level must come back down rather than keep growing")

        XCTAssertEqual(offset(Quat(angle: .degrees(180), axis: .xAxis)).height, 0, accuracy: 1e-9, "a point directly behind the device sits at the centre of the screen")
    }

    /// Limiting shortens the offset without turning it, so a diagonal tilt stays diagonal rather than sliding along an edge as it reaches the limit.
    func testLimitingShortensTheOffsetWithoutTurningIt() {
        let rotation = Quat(angle: .degrees(40), axis: Vec3(x: 1, y: 1, z: 0).normalized)
        let unlimited = offset(rotation)
        let limited = offset(rotation, maxOffset: 5)

        XCTAssertEqual(hypot(limited.width, limited.height), 5, accuracy: 1e-9)
        XCTAssertEqual(
            limited.width / limited.height,
            unlimited.width / unlimited.height,
            accuracy: 1e-9,
            "the limited offset points somewhere else"
        )
    }
}
