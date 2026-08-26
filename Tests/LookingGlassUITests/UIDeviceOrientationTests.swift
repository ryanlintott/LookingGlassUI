//
//  UIDeviceOrientationTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-26.
//

@testable import LookingGlassUI
import SwiftUI
import XCTest

@MainActor
final class UIDeviceOrientationTests: XCTestCase {
    /// The screen size comes from `UIScreen`, which a test can't rotate, so each orientation is checked against the portrait size rather than against fixed dimensions.
    private var portraitScreenSize: CGSize {
        get throws {
            try XCTUnwrap(UIDeviceOrientation.portrait.interfaceSize)
        }
    }

    /// The size comes from the screen's fixed coordinate space, whose bounds always reflect a portrait-up orientation however the app is oriented while the test runs.
    func testPortraitScreenSizeIsTallerThanItIsWide() throws {
        let portraitScreenSize = try portraitScreenSize

        XCTAssertGreaterThan(portraitScreenSize.height, portraitScreenSize.width)
    }

    func testLandscapeOrientationsSwapTheScreenSize() throws {
        let portraitScreenSize = try portraitScreenSize
        let landscapeScreenSize = CGSize(width: portraitScreenSize.height, height: portraitScreenSize.width)

        XCTAssertEqual(UIDeviceOrientation.landscapeLeft.interfaceSize, landscapeScreenSize)
        XCTAssertEqual(UIDeviceOrientation.landscapeRight.interfaceSize, landscapeScreenSize)
    }

    func testUpsideDownKeepsTheScreenSize() throws {
        XCTAssertEqual(UIDeviceOrientation.portraitUpsideDown.interfaceSize, try portraitScreenSize)
    }

    /// The interface never takes these orientations, so they must report no size rather than a portrait one that would be wrong while the interface was in landscape.
    func testOrientationsWithoutAnInterfaceHaveNoSize() {
        XCTAssertNil(UIDeviceOrientation.unknown.interfaceSize)
        XCTAssertNil(UIDeviceOrientation.faceUp.interfaceSize)
        XCTAssertNil(UIDeviceOrientation.faceDown.interfaceSize)
    }
}
