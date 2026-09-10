//
//  ShimmerMode.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2021-05-25.
//

import SwiftUI

/// Mode that toggles a `Bool` based on supplied `ColorScheme`
public enum ShimmerMode: Int, Sendable {
    case off, on, darkModeOnly, lightModeOnly
    
    /// A mode that is simply on or off, for a shimmer switched by a `Bool` rather than by color scheme.
    ///
    /// - Parameter isOn: Is shimmer enabled.
    /// - Returns: ``on`` or ``off``.
    public static func isOn(_ isOn: Bool) -> ShimmerMode {
        isOn ? .on : .off
    }
    
    /// Checks if shimmering should be on based on `ColorScheme`
    /// - Parameter colorScheme: Used to evaluate `Bool` state
    /// - Returns: on/off `Bool` based on supplied `ColorScheme`
    public func isOn(colorScheme: ColorScheme) -> Bool {
        switch self {
        case .off: false
        case .on: true
        case .darkModeOnly: colorScheme == .dark
        case .lightModeOnly: colorScheme == .light
        }
    }
}
