//
//  ShimmerLight.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-09-09.
//

import SwiftUI

/// The light a shimmer catches: an elliptical gradient reflected off a view as the device turns, and how it is drawn.
///
/// Every property but the color has a default, and those defaults are the light every shimmer effect drew before there was a light to pass around. How a light blends with the view underneath it belongs to the `shimmer` view modifiers that draw it there, not to the light.
public struct ShimmerLight: Equatable, Sendable {
    /// Color of the light.
    public var color: Color
    /// Color behind the light. Clear draws nothing where the light has faded out, leaving whatever it was drawn over.
    public var background: Color
    /// HDR exposure applied to the color on iOS 26 and later. Each stop doubles its brightness.
    public var exposureStops: Double
    /// Radius in points of the solid core at the centre of the light, before scaling.
    public var startRadius: CGFloat
    /// Radius in points the light has finished fading by, before scaling.
    public var endRadius: CGFloat
    /// Width of the light relative to its height. One is circular, below one is a tall narrow highlight, and above one a wide flat one.
    public var aspectRatio: CGFloat
    /// Distance in points the light sits in front of the device.
    public var distance: CGFloat
    /// Angle the light is pitched to where it sits in front of the device.
    public var pitch: Angle
    /// Angle the light is yawed to where it sits in front of the device.
    public var yaw: Angle
    /// Angle the light is rolled by where it sits in front of the device.
    public var rollAngle: Angle
    /// How much larger than its radius the light is drawn.
    ///
    /// The aspect ratio squeezes and stretches around this, so reshaping a light doesn't change how much of the view it covers.
    public var scale: CGFloat
    /// The way the light fades from its centre to its outer edge.
    public var falloff: ShimmerFalloff
    
    /// Creates a light for a shimmer effect to catch.
    ///
    /// Everything but the color has a default, and those defaults are the light every shimmer effect drew before there was a light to pass around, so a light is only worth building to change one of them.
    ///
    /// How a light blends with the view underneath it belongs to the `shimmer` view modifiers that draw it there, not to the light.
    ///
    /// - Parameters:
    ///   - color: Color of the light.
    ///   - background: Color behind the light. Clear draws nothing where the light has faded out, leaving whatever it was drawn over. (default: `.clear`)
    ///   - exposureStops: HDR exposure applied to the color on iOS 26 and later. Each stop doubles its brightness. Values that aren't positive and finite use standard dynamic range. (default: `0`)
    ///   - startRadius: Radius in points of the solid core at the centre of the light, before scaling. (default: `5`)
    ///   - endRadius: Radius in points the light has finished fading by, before scaling. (default: `125`)
    ///   - aspectRatio: Width of the light relative to its height. One is circular, below one is a tall narrow highlight, and above one a wide flat one. (default: `0.25`)
    ///   - distance: Distance in points the light sits in front of the device. (default: `4000`)
    ///   - pitch: Angle the light is pitched to where it sits in front of the device. (default: `45` degrees)
    ///   - yaw: Angle the light is yawed to where it sits in front of the device. (default: `.zero`)
    ///   - rollAngle: Angle the light is rolled by where it sits in front of the device. (default: `-30` degrees)
    ///   - scale: How much larger than its radius the light is drawn. Scaling up a light with a smaller radius (and smaller resolution) improves performance. (default: `5`)
    ///   - falloff: The way the light fades from its centre to its outer edge. (default: ``ShimmerFalloff/linear``)
    public init(
        color: Color,
        background: Color = .clear,
        exposureStops: Double = 0,
        startRadius: CGFloat = 5,
        endRadius: CGFloat = 125,
        aspectRatio: CGFloat = 0.25,
        distance: CGFloat = 4000,
        pitch: Angle = .degrees(45),
        yaw: Angle = .zero,
        rollAngle: Angle = .degrees(-30),
        scale: CGFloat = 5,
        falloff: ShimmerFalloff = .linear
    ) {
        self.color = color
        self.background = background
        self.exposureStops = exposureStops
        self.startRadius = startRadius
        self.endRadius = endRadius
        self.aspectRatio = aspectRatio
        self.distance = distance
        self.pitch = pitch
        self.yaw = yaw
        self.rollAngle = rollAngle
        self.scale = scale
        self.falloff = falloff
    }
    
    /// Scale applied to the gradient on each axis, ignoring values that would leave nothing to draw.
    ///
    /// The gradient starts out circular, so one axis is stretched by as much as the other is squeezed. Each takes the square root of the aspect ratio, which leaves the width divided by the height equal to the aspect ratio itself rather than to its square, and leaves the area the scale alone.
    ///
    /// A scale or aspect ratio of zero collapses the gradient and a negative one flips it or has no square root at all, so anything that isn't positive and finite is drawn unscaled.
    var gradientScale: CGSize {
        guard scale.isFinite, scale > 0, aspectRatio.isFinite, aspectRatio > 0 else { return CGSize(width: 1, height: 1) }
        let stretch = sqrt(aspectRatio)
        return CGSize(width: scale * stretch, height: scale / stretch)
    }
    
    /// HDR headroom the color is rendered with, or `nil` for standard dynamic range.
    private var hdrHeadroom: Double? {
        guard exposureStops.isFinite, exposureStops > 0 else { return nil }
        let headroom = pow(2, exposureStops)
        return headroom.isFinite ? headroom : nil
    }
    
    /// The color of the light, in HDR where it was asked for and is available.
    var exposedColor: Color {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), let hdrHeadroom {
            return color
                .exposureAdjust(exposureStops)
                .headroom(hdrHeadroom)
        }
        #endif
        return color
    }
    
    /// True if the color is rendered in HDR, which needs the dynamic range it's drawn in widened to allow it.
    var isHDREnabled: Bool {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            return hdrHeadroom != nil
        }
        #endif
        return false
    }
    
    /// The gradient this light draws, running from its centre to its outer edge.
    var gradient: Gradient {
        falloff.gradient(color: exposedColor, background: background)
    }
}
