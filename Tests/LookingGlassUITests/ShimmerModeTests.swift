//
//  ShimmerModeTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-09-09.
//

@testable import LookingGlassUI
import SwiftUI
import XCTest

/// `ShimmerMode` covers every way a shimmer can be on or off, including the `Bool` that used to need its own initializers.
final class ShimmerModeTests: XCTestCase {
    /// A `Bool` maps onto the two modes that don't depend on the color scheme, so a shimmer switched by one is the same shimmer as a mode set on or off.
    func testIsOnMapsToOnAndOff() {
        XCTAssertEqual(ShimmerMode.isOn(true), .on)
        XCTAssertEqual(ShimmerMode.isOn(false), .off)
    }

    /// Building a mode from a `Bool` and reading a mode share the name `isOn`. A mode built from a `Bool` has to answer that same `Bool` in either color scheme.
    func testModeBuiltFromABoolAnswersItInEitherColorScheme() {
        for colorScheme in [ColorScheme.light, .dark] {
            XCTAssertTrue(ShimmerMode.isOn(true).isOn(colorScheme: colorScheme))
            XCTAssertFalse(ShimmerMode.isOn(false).isOn(colorScheme: colorScheme))
        }
    }
}
