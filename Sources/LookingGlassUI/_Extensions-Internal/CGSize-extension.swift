//
//  CGSize-extension.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-25.
//

import CoreGraphics

extension CGSize {
    /// This size with the shorter dimension as the width.
    ///
    /// `UIScreen.main.bounds` is reported in the current interface orientation, so a size read from it needs normalising before it can be used as a portrait reference.
    var rotatedToPortrait: CGSize {
        CGSize(width: min(width, height), height: max(width, height))
    }
}
