//
//  File.swift
//  
//
//  Created by Ryan Lintott on 2021-05-25.
//

import SwiftUI

/// Mode that toggles a `Bool` based on supplied `ColorScheme`
@available(iOS 13, *)
public enum ShimmerMode: Int {
    case off, on, darkModeOnly, lightModeOnly
    
    /// Checks if shimmering should be on based on `ColorScheme`
    /// - Parameter colorScheme: Used to evaluate `Bool` state
    /// - Returns: on/off `Bool` based on supplied `ColorScheme`
    func isOn(colorScheme: ColorScheme) -> Bool {
        switch self {
        case .off:
            return false
        case .on:
            return true
        case .darkModeOnly:
            return colorScheme == .dark
        case .lightModeOnly:
            return colorScheme == .light
        }
    }
}
