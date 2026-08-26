//
//  ShimmerViewModifier.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2020-09-17.
//

import SwiftUI

struct ShimmerViewModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.motionUpdatesEnabled) private var motionUpdatesEnabled
    
    let mode: ShimmerMode
    let color: Color
    let background: Color
    let blendMode: BlendMode
    
    init(mode: ShimmerMode? = nil, color: Color, blendMode: BlendMode? = nil) {
        self.mode = mode ?? .on
        self.color = color
        self.background = .clear
        self.blendMode = blendMode ?? .screen
    }
    
    init(mode: ShimmerMode? = nil, color: Color, background: Color) {
        self.mode = mode ?? .on
        self.color = color
        self.background = background
        self.blendMode = .sourceAtop
    }
    
    /// True if anything needs to be drawn over the content.
    ///
    /// The background is drawn whether or not motion updates are running so the view doesn't change colour when motion is disabled. With a clear background there's nothing left to draw once the shimmer is off, and skipping it avoids compositing a fully transparent layer over the content every frame.
    var isVisible: Bool {
        mode.isOn(colorScheme: colorScheme) && (motionUpdatesEnabled || background != .clear)
    }
    
    @ViewBuilder
    func body(content: Content) -> some View {
        let _ = Self.printChangesIfEnabled()
        content
            .overlay(
                VStack {
                    if isVisible {
                        content
                            .hidden()
                            .overlay(
                                ShimmerView(mode: mode, color: color, background: background)
                            )
                            .mask(content)
                            .blendMode(blendMode)
                            .accessibilityHidden(true)
                            .allowsHitTesting(false)
                    }
                }
            )
    }
}

public extension View {
    /// Add a shimmer effect with a background masked to this view.
    ///
    /// - Requires: ``motionManager(updateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Note: This effect draws additional copies of the view to size the shimmer and to mask it to the view's shape. Each copy is a separate instance with its own state, so state inside the view that changes its size or shape may not be reflected in the shimmer, and any `onAppear` or `task` on the view may run more than once.
    ///
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled (default: `.on`)
    ///   - color: Shimmer color.
    ///   - background: Background color.
    /// - Returns: A shimmer effect with a background masked to this view.
    func shimmer(mode: ShimmerMode? = nil, color: Color, background: Color) -> some View {
        self.modifier(ShimmerViewModifier(mode: mode, color: color, background: background))
    }
    
    /// Add a shimmer effect with a background masked to this view.
    ///
    /// - Requires: ``motionManager(updateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Note: This effect draws additional copies of the view to size the shimmer and to mask it to the view's shape. Each copy is a separate instance with its own state, so state inside the view that changes its size or shape may not be reflected in the shimmer, and any `onAppear` or `task` on the view may run more than once.
    ///
    /// - Parameters:
    ///   - isOn: Is shimmer enabled (default: `true`)
    ///   - color: Shimmer color.
    ///   - background: Background color.
    /// - Returns: A shimmer effect with a background masked to this view.
    func shimmer(isOn: Bool, color: Color, background: Color) -> some View {
        self.modifier(ShimmerViewModifier(mode: isOn ? .on : .off, color: color, background: background))
    }
    
    /// Add a shimmer effect masked to this view with a specified blend mode.
    ///
    /// - Requires: ``motionManager(updateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Note: This effect draws additional copies of the view to size the shimmer and to mask it to the view's shape. Each copy is a separate instance with its own state, so state inside the view that changes its size or shape may not be reflected in the shimmer, and any `onAppear` or `task` on the view may run more than once.
    ///
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled (default: `.on`)
    ///   - color: Shimmer color
    ///   - blendMode: How shimmer will blend with other views. (default: `.screen`)
    /// - Returns: A view with a shimmer effect overlayed that is masked by the same view
    func shimmer(mode: ShimmerMode? = nil, color: Color, blendMode: BlendMode? = nil) -> some View {
        self.modifier(ShimmerViewModifier(mode: mode, color: color, blendMode: blendMode))
    }
    
    /// Add a shimmer effect masked to this view with a specified blend mode.
    ///
    /// - Requires: ``motionManager(updateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Note: This effect draws additional copies of the view to size the shimmer and to mask it to the view's shape. Each copy is a separate instance with its own state, so state inside the view that changes its size or shape may not be reflected in the shimmer, and any `onAppear` or `task` on the view may run more than once.
    ///
    /// - Parameters:
    ///   - isOn: Is shimmer enabled.
    ///   - color: Shimmer color
    ///   - blendMode: How shimmer will blend with other views. (default: `.screen`)
    /// - Returns: A view with a shimmer effect overlayed that is masked by the same view
    func shimmer(isOn: Bool, color: Color, blendMode: BlendMode? = nil) -> some View {
        self.modifier(ShimmerViewModifier(mode: isOn ? .on : .off, color: color, blendMode: blendMode))
    }
}
