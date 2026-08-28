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
    private func portraitScreenSize() throws -> CGSize {
        try XCTUnwrap(UIInterfaceOrientation.portrait.screenSize)
    }

    /// The size comes from the screen's fixed coordinate space, whose bounds always reflect a portrait-up orientation however the app is oriented while the test runs.
    func testPortraitScreenSizeIsTallerThanItIsWide() throws {
        let portrait = try portraitScreenSize()

        XCTAssertGreaterThan(portrait.height, portrait.width)
    }

    func testLandscapeOrientationsSwapTheScreenSize() throws {
        let portrait = try portraitScreenSize()
        let landscapeScreenSize = CGSize(width: portrait.height, height: portrait.width)

        XCTAssertEqual(UIInterfaceOrientation.landscapeLeft.screenSize, landscapeScreenSize)
        XCTAssertEqual(UIInterfaceOrientation.landscapeRight.screenSize, landscapeScreenSize)
    }

    func testPortraitOrientationsKeepTheScreenSize() throws {
        XCTAssertEqual(UIInterfaceOrientation.portraitUpsideDown.screenSize, try portraitScreenSize())
    }

    /// An unknown orientation says nothing about which way the screen is facing, so it must report no size at all rather than guessing at portrait and sizing content to a screen that may be turned the other way.
    func testUnknownOrientationHasNoScreenSize() {
        XCTAssertNil(UIInterfaceOrientation.unknown.screenSize)
    }
}
