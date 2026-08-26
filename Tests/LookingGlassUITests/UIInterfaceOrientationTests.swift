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
    /// The screen size comes from `UIScreen`, which a test can't rotate, so each orientation is checked against the portrait size rather than against fixed dimensions.
    private var portraitScreenSize: CGSize {
        UIInterfaceOrientation.portrait.screenSize
    }

    /// The size comes from the screen's fixed coordinate space, whose bounds always reflect a portrait-up orientation however the app is oriented while the test runs.
    func testPortraitScreenSizeIsTallerThanItIsWide() {
        XCTAssertGreaterThan(portraitScreenSize.height, portraitScreenSize.width)
    }

    func testLandscapeOrientationsSwapTheScreenSize() {
        let landscapeScreenSize = CGSize(width: portraitScreenSize.height, height: portraitScreenSize.width)

        XCTAssertEqual(UIInterfaceOrientation.landscapeLeft.screenSize, landscapeScreenSize)
        XCTAssertEqual(UIInterfaceOrientation.landscapeRight.screenSize, landscapeScreenSize)
    }

    func testPortraitOrientationsKeepTheScreenSize() {
        XCTAssertEqual(UIInterfaceOrientation.portraitUpsideDown.screenSize, portraitScreenSize)
        XCTAssertEqual(UIInterfaceOrientation.unknown.screenSize, portraitScreenSize)
    }

    /// The interface turns the opposite way to the device and the two use opposite names for landscape, so these signs are easy to get backwards. Landscape left is the interface turned left, which happens when the device is turned right.
    func testRotationCompensatesInTheOppositeDirectionToTheInterface() {
        XCTAssertEqual(UIInterfaceOrientation.landscapeLeft.rotation, Quat(angle: .radians(.pi / 2), axis: .zAxis))
        XCTAssertEqual(UIInterfaceOrientation.landscapeRight.rotation, Quat(angle: .radians(-.pi / 2), axis: .zAxis))
        XCTAssertEqual(UIInterfaceOrientation.portraitUpsideDown.rotation, Quat(angle: .radians(.pi), axis: .zAxis))
    }

    /// Portrait needs no compensation, and an unreadable orientation must behave as portrait rather than rotating the world by an arbitrary amount.
    func testPortraitAndUnknownNeedNoRotation() {
        XCTAssertEqual(UIInterfaceOrientation.portrait.rotation, .identity)
        XCTAssertEqual(UIInterfaceOrientation.unknown.rotation, .identity)
    }
}
