//
//  InfoDictionary.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2021-05-11.
//

import SwiftUI

enum InfoDictionary {
    /// Set of supported orientations for the current app
    static let supportedOrientations: Set<UIDeviceOrientation> = {
        if let orientations = Bundle.main.infoDictionary?["UISupportedInterfaceOrientations"] as? [String] {
            return Set(orientations.compactMap({ UIDeviceOrientation(key: $0) }))
        } else {
            return []
        }
    }()
}
