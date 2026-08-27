//
//  UIInterfaceOrientation-extension.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-26.
//

import SwiftUI

extension UIInterfaceOrientation {
    /// The orientation the interface is currently showing.
    ///
    /// This is what the interface is facing, unlike `UIDevice.current.orientation`, which reports where the device is physically pointing. That is unknown at launch and face up or face down whenever the device is lying flat, none of which say which way the interface is facing.
    ///
    /// - Returns: The orientation of a window scene on the device's own screen, or `nil` when no such scene reports one.
    @MainActor
    static var current: UIInterfaceOrientation? {
        /// Interface orientation belongs to a window scene, and a window scene belongs to a screen. A scene on an external display has an orientation of its own that says nothing about how the device is being held, so only scenes on the device's own screen are asked. That also keeps this paired with ``screenSize``, which measures that screen.
        let windowScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .filter { $0.screen === UIScreen.main }

        /// A scene outside the foreground can report a stale orientation, but during launch there may not be an active one yet and any connected scene is better than nothing.
        let windowScene = windowScenes.first { $0.activationState == .foregroundActive }
            ?? windowScenes.first { $0.activationState == .foregroundInactive }
            ?? windowScenes.first

        guard let interfaceOrientation = windowScene?.interfaceOrientation,
              interfaceOrientation != .unknown else {
            return nil
        }

        return interfaceOrientation
    }

    /// The screen size in this interface orientation.
    ///
    /// `UIScreen.bounds` is also reported in the current interface orientation but can lag a rotation, so the fixed coordinate space is used instead. Its bounds always reflect a portrait-up orientation and are measured in points.
    @MainActor
    var screenSize: CGSize? {
        let portraitScreenSize = UIScreen.main.fixedCoordinateSpace.bounds.size

        switch self {
        case .landscapeLeft, .landscapeRight:
            return CGSize(width: portraitScreenSize.height, height: portraitScreenSize.width)
        case .portrait, .portraitUpsideDown:
            return portraitScreenSize
        case .unknown:
            return nil
        @unknown default:
            return nil
        }
    }

    /// The quaternion that compensates for this interface orientation.
    ///
    /// The interface rotates in the opposite direction to the device, and the two use opposite names for landscape: `UIInterfaceOrientation.landscapeLeft` is the interface turned to the left, which is what happens when the device is turned to the right.
    ///
    /// Device reference frame.
    var rotation: Quat {
        switch self {
        // interface turned to the left, device turned to the right
        case .landscapeLeft:
            return Quat(angle: .radians(.pi / 2), axis: .zAxis)
        // interface turned to the right, device turned to the left
        case .landscapeRight:
            return Quat(angle: .radians(-.pi / 2), axis: .zAxis)
        case .portraitUpsideDown:
            return Quat(angle: .radians(.pi), axis: .zAxis)
        case .portrait, .unknown:
            return .identity
        @unknown default:
            return .identity
        }
    }
}
