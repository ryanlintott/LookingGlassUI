//
//  MaskedOverlayViewModifier.swift
//  ReflectiveUI
//
//  Created by Ryan Lintott on 2020-09-18.
//

import SwiftUI

@available(iOS 13, *)
struct MaskedOverlayViewModifier<OverlayContent: View>: ViewModifier {
    let overlayContent: OverlayContent
    let alignment: Alignment
    let blendMode: BlendMode
    
    func body(content: Content) -> some View {
        content
            .overlay(
                overlayContent
                    .blendMode(blendMode)
                    .allowsHitTesting(false)
                ,
                alignment: alignment
            )
            .mask(
                content
            )
    }
}

@available(iOS 13, *)
extension View {
    /// Overlays a secondary view then uses primary view as a mask
    /// - Returns: A view that overlays a secondary view in front then masks it by the primary view
    func maskedOverlay<OverlayContent: View>(_ overlayContent: OverlayContent, alignment: Alignment = .center, blendMode: BlendMode = .normal) -> some View {
        self.modifier(MaskedOverlayViewModifier(overlayContent: overlayContent, alignment: alignment, blendMode: blendMode))
    }
}
