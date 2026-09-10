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
    /// Size of the light in points, as it ends up on screen.
    public var size: CGSize
    /// The fraction of its size the light is actually drawn at before being stretched back up to fill it.
    ///
    /// A gradient drawn small and scaled up costs much less to draw than the same gradient drawn full size, and a light this soft has little detail to lose. Lower values are cheaper and softer, and one draws the light at full size.
    public var resolution: CGFloat
    /// Pitch rotation placing the light in the real world (zero = on the ground, 90 degrees = in front, 180 degrees = on the ceiling).
    public var pitch: Angle
    /// Yaw rotation placing the light in the real world (zero = in front, 90 degrees = left, -90 degrees = right, 180 degrees = behind).
    ///
    /// A shimmer shows its light in all four directions, so this turns it within each rather than picking one to face.
    public var yaw: Angle
    /// Local roll turning the light about its own centre, tilting the ellipse where it hangs in the world.
    public var localRoll: Angle
    /// The way the light fades from its centre to its outer edge.
    public var falloff: ShimmerFalloff
    
    /// Distance in points the light hangs in front of the device.
    ///
    /// A shimmer is drawn without perspective, so nothing about the light changes with the distance it's placed at. It's kept because ``LookingGlass`` asks for one, and far enough away that a light is never behind the screen.
    let distance: CGFloat = 4000
    
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
    ///   - size: Size of the light in points, as it ends up on screen. (default: `625` × `2500`)
    ///   - resolution: The fraction of its size the light is drawn at before being stretched back up to fill it. Drawing small and scaling up costs much less than drawing full size, and a light this soft has little detail to lose. Values that aren't positive and finite draw the light at full size. (default: `0.2`)
    ///   - pitch: Pitch rotation placing the light in the real world (zero = on the ground, 90 degrees = in front, 180 degrees = on the ceiling). (default: `45` degrees, halfway between the two)
    ///   - yaw: Yaw rotation placing the light in the real world (zero = in front, 90 degrees = left, -90 degrees = right, 180 degrees = behind). (default: `.zero`)
    ///   - localRoll: Local roll turning the light about its own centre, tilting the ellipse where it hangs in the world. (default: `-30` degrees)
    ///   - falloff: The way the light fades from its centre to its outer edge. (default: ``ShimmerFalloff/linear(core:)``)
    public init(
        color: Color,
        background: Color = .clear,
        exposureStops: Double = 0,
        size: CGSize = CGSize(width: 625, height: 2500),
        resolution: CGFloat = 0.2,
        pitch: Angle = .degrees(45),
        yaw: Angle = .zero,
        localRoll: Angle = .degrees(-30),
        falloff: ShimmerFalloff = .linear()
    ) {
        self.color = color
        self.background = background
        self.exposureStops = exposureStops
        self.size = size
        self.pitch = pitch
        self.yaw = yaw
        self.localRoll = localRoll
        self.resolution = resolution
        self.falloff = falloff
    }
    
    /// Width of the light relative to its height. One is circular, below one is a tall narrow highlight, and above one a wide flat one.
    ///
    /// Derived from ``size``, which is what the light is actually drawn to.
    public var aspectRatio: CGFloat {
        guard size.width.isFinite, size.height.isFinite, size.height > 0 else { return 0 }
        return size.width / size.height
    }
    
    /// The resolution the light is drawn at, ignoring values that would leave nothing to draw.
    private var drawnResolution: CGFloat {
        guard resolution.isFinite, resolution > 0 else { return 1 }
        return resolution
    }
    
    /// Width and height in points of the square the gradient is drawn in before it's stretched into the light.
    ///
    /// The gradient is a circle, so it's drawn square and stretched to the light's size afterwards. Taking the resolution off both sides of that square, rather than off the width or the height, leaves the amount it has to be scaled up by the same on average whatever shape the light is, so a light keeps the same softness as it's reshaped.
    ///
    /// Zero where there is no light to draw, which leaves the gradient an empty frame.
    var gradientDiameter: CGFloat {
        guard size.width.isFinite, size.width > 0, size.height.isFinite, size.height > 0 else { return 0 }
        return sqrt(size.width * size.height) * drawnResolution
    }
    
    /// Radius in points the gradient is drawn to before being stretched.
    var gradientRadius: CGFloat {
        gradientDiameter / 2
    }
    
    /// Radius in points the gradient is solid color to before it starts to fade, before being stretched.
    ///
    /// The size of that core belongs to the falloff, which is the shape of the light from its centre to its edge; this is only where it lands in the gradient being drawn.
    var gradientCoreRadius: CGFloat {
        gradientRadius * CGFloat(falloff.drawnCore)
    }
    
    /// Scale applied to the drawn gradient on each axis to stretch it into the light.
    ///
    /// Dividing the light's size by the square it was drawn in leaves it exactly ``size`` on screen, however small it was drawn.
    var gradientScale: CGSize {
        let diameter = gradientDiameter
        guard diameter > 0 else { return CGSize(width: 1, height: 1) }
        return CGSize(width: size.width / diameter, height: size.height / diameter)
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
