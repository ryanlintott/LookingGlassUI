//
//  ShimmerViewModifier.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2020-09-17.
//

import SwiftUI

struct ShimmerViewModifier: ViewModifier {
    @EnvironmentObject private var motionManager: MotionManager
    @Environment(\.colorScheme) private var colorScheme
    
    let mode: ShimmerMode
    let light: ShimmerLight
    let blendMode: BlendMode
    
    init(mode: ShimmerMode? = nil, light: ShimmerLight, blendMode: BlendMode) {
        self.mode = mode ?? .on
        self.light = light
        self.blendMode = blendMode
    }
    
    /// True if anything needs to be drawn over the content.
    ///
    /// The background is drawn whenever there is one, whatever the mode and whether or not motion updates are running, so the view doesn't change colour when the shimmer can't appear. That matches ``ShimmerView``. With a clear background there's nothing left to draw once the shimmer is off, and skipping it avoids compositing a fully transparent layer over the content every frame.
    var isVisible: Bool {
        light.background != .clear || (motionManager.isDetectingMotion && mode.isOn(colorScheme: colorScheme))
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        let _ = Self.printChangesIfEnabled()
        content
            .overlay {
                if isVisible {
                    content
                        .hidden()
                        .overlay {
                            ShimmerView(mode: mode, light: light)
                        }
                        .mask { content }
                        .blendMode(blendMode)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
            }
    }
}

extension ShimmerLight {
    /// The blend that suits this light where the view drawing it doesn't name one.
    ///
    /// A light with a background paints that background over the view, so it's laid on top of what's already there. A light without one only adds light to it. These are the two blends the `shimmer` view modifiers have always come in.
    var suggestedBlendMode: BlendMode {
        background == .clear ? .screen : .sourceAtop
    }
}

public extension View {
    /// Add a shimmer effect with a background masked to this view.
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Note: This effect draws additional copies of the view to size the shimmer and to mask it to the view's shape. Each copy is a separate instance with its own state, so state inside the view that changes its size or shape may not be reflected in the shimmer, and any `onAppear` or `task` on the view may run more than once.
    ///
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled (default: `.on`)
    ///   - light: The light being caught, including the color it's drawn in and where it sits in front of the device.
    ///   - blendMode: How shimmer will blend with this view. A light with a background is laid on top of it with `.sourceAtop` and a light without one adds to it with `.screen`. (default: whichever suits the light)
    /// - Returns: A shimmer effect masked to this view.
    func shimmer(mode: ShimmerMode? = nil, light: ShimmerLight, blendMode: BlendMode? = nil) -> some View {
        self.modifier(ShimmerViewModifier(mode: mode, light: light, blendMode: blendMode ?? light.suggestedBlendMode))
    }
    
    /// Add a shimmer effect with a background masked to this view.
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Note: This effect draws additional copies of the view to size the shimmer and to mask it to the view's shape. Each copy is a separate instance with its own state, so state inside the view that changes its size or shape may not be reflected in the shimmer, and any `onAppear` or `task` on the view may run more than once.
    ///
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled (default: `.on`)
    ///   - color: ShimmerLight color.
    ///   - background: Background color.
    /// - Returns: A shimmer effect with a background masked to this view.
    func shimmer(mode: ShimmerMode? = nil, color: Color, background: Color) -> some View {
        self.shimmer(mode: mode, light: ShimmerLight(color: color, background: background), blendMode: .sourceAtop)
    }
    
    /// Add a shimmer effect with a background masked to this view.
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Note: This effect draws additional copies of the view to size the shimmer and to mask it to the view's shape. Each copy is a separate instance with its own state, so state inside the view that changes its size or shape may not be reflected in the shimmer, and any `onAppear` or `task` on the view may run more than once.
    ///
    /// - Parameters:
    ///   - isOn: Is shimmer enabled (default: `true`)
    ///   - color: ShimmerLight color.
    ///   - background: Background color.
    /// - Returns: A shimmer effect with a background masked to this view.
    @available(*, deprecated, message: "Use shimmer(mode:color:background:) with .isOn(isOn). One mode parameter covers every way a shimmer can be on or off, including a Bool.")
    func shimmer(isOn: Bool, color: Color, background: Color) -> some View {
        self.shimmer(mode: .isOn(isOn), color: color, background: background)
    }
    
    /// Add a shimmer effect masked to this view with a specified blend mode.
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Note: This effect draws additional copies of the view to size the shimmer and to mask it to the view's shape. Each copy is a separate instance with its own state, so state inside the view that changes its size or shape may not be reflected in the shimmer, and any `onAppear` or `task` on the view may run more than once.
    ///
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled (default: `.on`)
    ///   - color: ShimmerLight color
    ///   - blendMode: How shimmer will blend with other views. (default: `.screen`)
    /// - Returns: A view with a shimmer effect overlayed that is masked by the same view
    func shimmer(mode: ShimmerMode? = nil, color: Color, blendMode: BlendMode? = nil) -> some View {
        self.shimmer(mode: mode, light: ShimmerLight(color: color), blendMode: blendMode ?? .screen)
    }
    
    /// Add a shimmer effect masked to this view with a specified blend mode.
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Note: This effect draws additional copies of the view to size the shimmer and to mask it to the view's shape. Each copy is a separate instance with its own state, so state inside the view that changes its size or shape may not be reflected in the shimmer, and any `onAppear` or `task` on the view may run more than once.
    ///
    /// - Parameters:
    ///   - isOn: Is shimmer enabled.
    ///   - color: ShimmerLight color
    ///   - blendMode: How shimmer will blend with other views. (default: `.screen`)
    /// - Returns: A view with a shimmer effect overlayed that is masked by the same view
    @available(*, deprecated, message: "Use shimmer(mode:color:blendMode:) with .isOn(isOn). One mode parameter covers every way a shimmer can be on or off, including a Bool.")
    func shimmer(isOn: Bool, color: Color, blendMode: BlendMode? = nil) -> some View {
        self.shimmer(mode: .isOn(isOn), color: color, blendMode: blendMode)
    }
}
