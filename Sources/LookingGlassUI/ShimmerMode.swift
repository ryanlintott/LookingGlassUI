//
//  File.swift
//  
//
//  Created by Ryan Lintott on 2021-05-25.
//

import SwiftUI

@available(iOS 13, *)
public enum ShimmerMode {
    case on, lightModeOnly, darkModeOnly, off
    
    func isOn(colorScheme: ColorScheme) -> Bool {
        switch self {
        case .on:
            return true
        case .off:
            return false
        case .lightModeOnly:
            return colorScheme == .light
        case .darkModeOnly:
            return colorScheme == .dark
        }
    }
}
