//
//  ShimmerFalloff.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-09-09.
//

import SwiftUI

/// The way a ``ShimmerLight`` fades from its centre to its outer edge.
public struct ShimmerFalloff: Equatable, Sendable {
    /// Opacities of the shimmer color, evenly spaced from the centre of the light to its outer edge, or `nil` to run straight from the shimmer color to the background color.
    let intensities: [Double]?
    
    /// Number of straight segments a curve is sampled into.
    ///
    /// A `Gradient` only interpolates linearly between its stops, so any curve has to be approximated. More segments are smoother at the cost of a larger gradient.
    static let segments = 16
    
    private init(intensities: [Double]?) {
        self.intensities = intensities
    }
    
    /// A fade running in a straight line from the shimmer color to the background color.
    ///
    /// Half the radius sits above half brightness, which reads as one large soft blob.
    public static let linear = ShimmerFalloff(intensities: nil)
    
    /// A fade dropping as the distance from the centre, subtracted from one, raised to `exponent`.
    ///
    /// An exponent above one drops the brightness quickly at first and then trails off, so the brightest part stays small while the faint halo around it still reaches the outer edge, closer to light glancing off a surface. Below one it does the reverse, holding the brightness and then falling away at the edge.
    ///
    /// - Parameter exponent: How sharply the light fades. `1` is ``linear``. Values that aren't positive and finite are also ``linear``.
    public static func power(_ exponent: Double) -> ShimmerFalloff {
        guard exponent.isFinite, exponent > 0, exponent != 1 else { return .linear }
        return ShimmerFalloff(intensities: (0...segments).map { segment in
            pow(1 - Double(segment) / Double(segments), exponent)
        })
    }
    
    /// A fade through the supplied opacities, spaced evenly from the centre of the light to its outer edge.
    ///
    /// Use this to shape a light that none of the other falloffs describe. Start at `1` and end at `0` for a light that is fully the shimmer color at its centre and gone by its edge.
    ///
    /// - Parameter intensities: Opacities of the shimmer color from centre to edge. Each is clamped to `0...1`, and fewer than two leaves nothing to interpolate so the falloff is ``linear``.
    public static func intensities(_ intensities: [Double]) -> ShimmerFalloff {
        guard intensities.count > 1 else { return .linear }
        return ShimmerFalloff(intensities: intensities.map { $0.isFinite ? min(max($0, 0), 1) : 0 })
    }
    
    /// The gradient a light with this falloff draws.
    ///
    /// A straight line is the two color gradient it has always been, so the default light costs nothing extra to draw.
    ///
    /// Every other falloff fades the shimmer color's opacity rather than running towards `background`. Mixing two colors to find the stops in between needs `Color.mix(with:by:)`, which is iOS 18 and later, and fading opacity works just as well for the blend mode versions of `shimmer` where the background is clear. The shimmer is drawn directly on top of `background` so the fade still ends on that color, but its midtones don't land exactly where interpolating colors would put them, and read a little brighter.
    ///
    /// - Parameters:
    ///   - color: ShimmerLight color at the centre of the light.
    ///   - background: Background color the light fades into.
    /// - Returns: A gradient running from the centre of the light to its outer edge.
    func gradient(color: Color, background: Color) -> Gradient {
        guard let intensities else {
            return Gradient(colors: [color, background])
        }
        let lastIndex = Double(intensities.count - 1)
        return Gradient(stops: intensities.enumerated().map { index, intensity in
            /// A fully opaque stop is the shimmer color itself. Asking for its opacity would wrap it in a modifier that changes nothing, and leaving an HDR color unwrapped is one less thing between it and the screen.
            let stopColor = intensity == 1 ? color : color.opacity(intensity)
            return Gradient.Stop(color: stopColor, location: Double(index) / lastIndex)
        })
    }
}
