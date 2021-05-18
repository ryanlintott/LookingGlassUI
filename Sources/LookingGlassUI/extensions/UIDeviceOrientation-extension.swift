//
//  UIDeviceOrientation-extension.swift
//  ReflectiveUI
//
//  Created by Ryan Lintott on 2021-05-14.
//

import SwiftUI

extension UIDeviceOrientation {
    init?(key: String) {
        switch key {
        case "UIInterfaceOrientationPortrait":
            self = .portrait
        case "UIInterfaceOrientationLandscapeLeft":
            /// UIInterfaceOrientationLandscapeLeft means the interface has turned to the LEFT even though the device has turned to the RIGHT.
            self = .landscapeRight
        case "UIInterfaceOrientationLandscapeRight":
            /// UIInterfaceOrientationLandscapeLeft means the interface has turned to the RIGHT even though the device has turned to the LEFT.
            self = .landscapeLeft
        case "UIInterfaceOrientationPortraitUpsideDown":
            self = .portraitUpsideDown
        case "UIInterfaceOrientationUnknown":
            self = .unknown
        default:
            return nil
        }
    }
    
    var string: String {
        switch self {
        case .portrait:
            return "portrait"
        case .landscapeLeft:
            return "landscapeLeft"
        case .landscapeRight:
            return "landscapeRight"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .unknown:
            return "unknown"
        case .faceUp:
            return "faceUp"
        case .faceDown:
            return "faceDown"
        default:
            return "*new case*"
        }
    }
}
