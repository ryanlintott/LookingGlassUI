//
//  MotionManagerTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-25.
//

@testable import LookingGlassUI
import SwiftUI
import XCTest

@MainActor
final class MotionManagerScreenSizeTests: XCTestCase {
    /// `UIScreen.main.bounds` reports the current interface orientation and is captured once, so a launch in landscape used to invert the width and height that `interfaceSize` then swapped, making the shimmer the wrong size in both orientations.
    func testRotatedToPortraitNormalisesLandscapeSize() {
        XCTAssertEqual(CGSize(width: 1024, height: 768).rotatedToPortrait, CGSize(width: 768, height: 1024))
    }

    func testRotatedToPortraitLeavesPortraitSizeAlone() {
        XCTAssertEqual(CGSize(width: 768, height: 1024).rotatedToPortrait, CGSize(width: 768, height: 1024))
    }

    func testPortraitScreenSizeIsPortraitShaped() {
        let size = MotionManager.portraitScreenSize
        XCTAssertLessThanOrEqual(size.width, size.height, "portraitScreenSize must have the shorter dimension as its width whatever orientation the app is in")
    }
}
