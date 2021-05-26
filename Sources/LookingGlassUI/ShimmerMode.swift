//
//  File.swift
//  
//
//  Created by Ryan Lintott on 2021-05-25.
//

import SwiftUI

@available(iOS 13, *)
public enum ShimmerMode: Int {
    case off, on, darkModeOnly, lightModeOnly
    
    func isOn(colorScheme: @autoclosure () -> ColorScheme) -> Bool {
        switch self {
        case .off:
            return false
        case .on:
            return true
        case .darkModeOnly:
            return colorScheme() == .dark
        case .lightModeOnly:
            return colorScheme() == .light
        }
    }
}
