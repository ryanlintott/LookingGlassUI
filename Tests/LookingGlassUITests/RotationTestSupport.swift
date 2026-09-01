//
//  RotationTestSupport.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-28.
//

@testable import LookingGlassUI
import SwiftUI
import XCTest

/// Asserts that two quaternions describe the same rotation.
///
/// Quaternions double cover rotations, so `q` and `-q` turn a view to exactly the same place while differing in every component. Comparing them with `XCTAssertEqual` fails on that pair and on the last bit of any composition, so rotations are compared by the angle between them instead.
func assertSameRotation(
    _ actual: Quat,
    _ expected: Quat,
    accuracy: Angle = .degrees(1e-9),
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line
) {
    let difference = abs((actual.inverse * expected).angle.degrees)
    /// Zero and a full turn are both "no rotation between them", the second being the `-q` representation.
    let error = min(difference, abs(360 - difference))

    XCTAssertEqual(
        error,
        0,
        accuracy: accuracy.degrees,
        message(),
        file: file,
        line: line
    )
}

/// Device attitudes to test rotations against.
enum Attitude {
    /// A device tilted away from lying flat, with its back pointing along a compass bearing.
    ///
    /// Bearing zero points the back of the device along the positive y axis, which is the direction the top of the device points when it lies flat. Increasing the bearing sweeps it towards the positive x axis.
    ///
    /// - Parameters:
    ///   - bearing: The horizontal direction the back of the device points.
    ///   - tilt: How far the device is tilted up from lying flat. Enough of a tilt to give the bearing meaning, but short of pointing at the horizon where it becomes ambiguous.
    static func pointing(bearing: Angle, tilt: Angle = .degrees(60)) -> Quat {
        Quat(angle: bearing, axis: .zAxis) * Quat(angle: tilt, axis: .xAxis)
    }

    /// A spread of unrelated device poses, for checking that something is independent of how the device is held.
    ///
    /// Deliberately not a sweep of one axis: a value that depends on the attitude in a way a single axis happens to miss would survive that.
    static let spread: [(name: String, attitude: Quat)] = [
        ("lying flat", .identity),
        ("held upright", Quat(angle: .degrees(90), axis: .zAxis) * Quat(angle: .degrees(90), axis: .xAxis)),
        ("tilted towards the viewer", Quat(angle: .degrees(20), axis: .xAxis)),
        ("tilted on its side", Quat(angle: .degrees(70), axis: .yAxis)),
        ("off every axis", Quat(angle: .degrees(35), axis: Vec3(x: 0.4, y: 0.3, z: 0.87).normalized)),
    ]
}

extension UIInterfaceOrientation {
    /// The interface orientations an app can actually be shown in, which is every case except `unknown`.
    static let allShowable: [UIInterfaceOrientation] = [.portrait, .landscapeLeft, .landscapeRight, .portraitUpsideDown]

    /// A readable name for test failure messages, as the raw value alone doesn't say which orientation it is.
    var testName: String {
        switch self {
        case .portrait: "portrait"
        case .portraitUpsideDown: "portrait upside down"
        case .landscapeLeft: "landscape left"
        case .landscapeRight: "landscape right"
        case .unknown: "unknown"
        @unknown default: "unknown"
        }
    }
}
