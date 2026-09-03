//
//  UIInterfaceOrientation-extension.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-26.
//

import SwiftUI

extension UIInterfaceOrientation {
    /// Rotates a view from this interface orientation so it points the top of the device in the device reference frame.
    ///
    /// The interface rotates in the opposite direction to the device, and the two use opposite names for landscape: `UIInterfaceOrientation.landscapeLeft` is the interface turned to the left, which is what happens when the device is turned to the right.
    var rotation: Quat? {
        switch self {
        // interface turned to the left, device turned to the right
        case .landscapeLeft:
            Quat(angle: .radians(.pi / 2), axis: .zAxis)
        // interface turned to the right, device turned to the left
        case .landscapeRight:
            Quat(angle: .radians(-.pi / 2), axis: .zAxis)
        case .portraitUpsideDown:
            Quat(angle: .radians(.pi), axis: .zAxis)
        case .portrait:
            .identity
        case .unknown:
            nil
        @unknown default:
            nil
        }
    }
}
