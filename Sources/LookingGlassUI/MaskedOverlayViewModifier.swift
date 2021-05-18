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
    func maskedOverlay<OverlayContent: View>(_ overlayContent: OverlayContent, alignment: Alignment = .center, blendMode: BlendMode = .normal) -> some View {
        self.modifier(MaskedOverlayViewModifier(overlayContent: overlayContent, alignment: alignment, blendMode: blendMode))
    }
}
