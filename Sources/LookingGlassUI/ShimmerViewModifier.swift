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
    let color: Color
    let background: Color
    let blendMode: BlendMode
    let exposureStops: Double
    
    init(mode: ShimmerMode? = nil, color: Color, blendMode: BlendMode? = nil, exposureStops: Double = 0) {
        self.mode = mode ?? .on
        self.color = color
        self.background = .clear
        self.blendMode = blendMode ?? .screen
        self.exposureStops = exposureStops
    }
    
    init(mode: ShimmerMode? = nil, color: Color, background: Color, exposureStops: Double = 0) {
        self.mode = mode ?? .on
        self.color = color
        self.background = background
        self.blendMode = .sourceAtop
        self.exposureStops = exposureStops
    }
    
    /// True if anything needs to be drawn over the content.
    ///
    /// The background is drawn whenever there is one, whatever the mode and whether or not motion updates are running, so the view doesn't change colour when the shimmer can't appear. That matches ``ShimmerView``. With a clear background there's nothing left to draw once the shimmer is off, and skipping it avoids compositing a fully transparent layer over the content every frame.
    var isVisible: Bool {
        background != .clear || (motionManager.isDetectingMotion && mode.isOn(colorScheme: colorScheme))
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
                            ShimmerView(mode: mode, color: color, background: background, exposureStops: exposureStops)
                        }
                        .mask { content }
                        .blendMode(blendMode)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
            }
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
    ///   - color: Shimmer color.
    ///   - background: Background color.
    ///   - exposureStops: HDR exposure applied to the shimmer color on iOS 26 and later. Each stop doubles its brightness. Values that are zero, negative, or infinite use standard dynamic range. (default: `0`)
    /// - Returns: A shimmer effect with a background masked to this view.
    func shimmer(mode: ShimmerMode? = nil, color: Color, background: Color, exposureStops: Double = 0) -> some View {
        self.modifier(ShimmerViewModifier(mode: mode, color: color, background: background, exposureStops: exposureStops))
    }
    
    /// Add a shimmer effect with a background masked to this view.
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Note: This effect draws additional copies of the view to size the shimmer and to mask it to the view's shape. Each copy is a separate instance with its own state, so state inside the view that changes its size or shape may not be reflected in the shimmer, and any `onAppear` or `task` on the view may run more than once.
    ///
    /// - Parameters:
    ///   - isOn: Is shimmer enabled (default: `true`)
    ///   - color: Shimmer color.
    ///   - background: Background color.
    ///   - exposureStops: HDR exposure applied to the shimmer color on iOS 26 and later. Each stop doubles its brightness. Values that are zero, negative, or infinite use standard dynamic range. (default: `0`)
    /// - Returns: A shimmer effect with a background masked to this view.
    func shimmer(isOn: Bool, color: Color, background: Color, exposureStops: Double = 0) -> some View {
        self.modifier(ShimmerViewModifier(mode: isOn ? .on : .off, color: color, background: background, exposureStops: exposureStops))
    }
    
    /// Add a shimmer effect masked to this view with a specified blend mode.
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Note: This effect draws additional copies of the view to size the shimmer and to mask it to the view's shape. Each copy is a separate instance with its own state, so state inside the view that changes its size or shape may not be reflected in the shimmer, and any `onAppear` or `task` on the view may run more than once.
    ///
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled (default: `.on`)
    ///   - color: Shimmer color
    ///   - blendMode: How shimmer will blend with other views. (default: `.screen`)
    ///   - exposureStops: HDR exposure applied to the shimmer color on iOS 26 and later. Each stop doubles its brightness. Values that are zero, negative, or infinite use standard dynamic range. (default: `0`)
    /// - Returns: A view with a shimmer effect overlayed that is masked by the same view
    func shimmer(mode: ShimmerMode? = nil, color: Color, blendMode: BlendMode? = nil, exposureStops: Double = 0) -> some View {
        self.modifier(ShimmerViewModifier(mode: mode, color: color, blendMode: blendMode, exposureStops: exposureStops))
    }
    
    /// Add a shimmer effect masked to this view with a specified blend mode.
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Note: This effect draws additional copies of the view to size the shimmer and to mask it to the view's shape. Each copy is a separate instance with its own state, so state inside the view that changes its size or shape may not be reflected in the shimmer, and any `onAppear` or `task` on the view may run more than once.
    ///
    /// - Parameters:
    ///   - isOn: Is shimmer enabled.
    ///   - color: Shimmer color
    ///   - blendMode: How shimmer will blend with other views. (default: `.screen`)
    ///   - exposureStops: HDR exposure applied to the shimmer color on iOS 26 and later. Each stop doubles its brightness. Values that are zero, negative, or infinite use standard dynamic range. (default: `0`)
    /// - Returns: A view with a shimmer effect overlayed that is masked by the same view
    func shimmer(isOn: Bool, color: Color, blendMode: BlendMode? = nil, exposureStops: Double = 0) -> some View {
        self.modifier(ShimmerViewModifier(mode: isOn ? .on : .off, color: color, blendMode: blendMode, exposureStops: exposureStops))
    }
}
