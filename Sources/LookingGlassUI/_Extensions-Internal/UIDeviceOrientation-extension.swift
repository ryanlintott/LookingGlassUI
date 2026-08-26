//
//  UIDeviceOrientation-extension.swift
//  LookingGlassUI
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
    
    /// The screen size in the interface orientation matching this device orientation.
    ///
    /// `nil` for orientations the interface never takes, including face up, face down, and unknown. They say nothing about which way the interface is facing, so a caller tracking the size should keep the one it has.
    @MainActor
    var interfaceSize: CGSize? {
        /// `UIScreen.bounds` is reported in the current interface orientation, which lags a device orientation change, so the fixed coordinate space is used instead. Its bounds always reflect a portrait-up orientation and are measured in points.
        let portraitScreenSize = UIScreen.main.fixedCoordinateSpace.bounds.size

        switch self {
        case .portrait, .portraitUpsideDown:
            return portraitScreenSize
        case .landscapeLeft, .landscapeRight:
            return CGSize(width: portraitScreenSize.height, height: portraitScreenSize.width)
        case .unknown, .faceUp, .faceDown:
            return nil
        @unknown default:
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
