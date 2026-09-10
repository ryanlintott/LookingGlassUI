//
//  ShimmerLightTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-09-09.
//

@testable import LookingGlassUI
import SwiftUI
import XCTest

/// A `ShimmerLight` describes the gradient a shimmer reflects. These cover the shape of that gradient, and that a light nobody has changed still draws what shimmer drew when none of it could be changed.
final class ShimmerLightTests: XCTestCase {
    private let color = Color.red
    private let background = Color.blue

    /// The values that were fixed inside `ShimmerView` before there was a light to pass it. Changing any of these changes how every existing shimmer looks.
    func testDefaultsMatchTheValuesTheyReplaced() {
        let light = ShimmerLight(color: color, background: background)

        XCTAssertEqual(light.exposureStops, 0)
        XCTAssertEqual(light.startRadius, 5)
        XCTAssertEqual(light.endRadius, 125)
        XCTAssertEqual(light.aspectRatio, 0.25)
        XCTAssertEqual(light.distance, 4000)
        XCTAssertEqual(light.pitch, .degrees(45))
        XCTAssertEqual(light.yaw, .zero)
        XCTAssertEqual(light.rollAngle, .degrees(-30))
        XCTAssertEqual(light.scale, 5)
        XCTAssertEqual(light.falloff, .linear)
        XCTAssertFalse(light.isHDREnabled)
    }

    /// A light keeps whatever background it was given, and has none unless it was given one.
    func testLightHasNoBackgroundUnlessGivenOne() {
        XCTAssertEqual(ShimmerLight(color: color, background: background).background, background)
        XCTAssertEqual(ShimmerLight(color: color).background, .clear)
    }

    /// Blending belongs to the modifier drawing the light, not to the light. A light with a background is laid over the view, and one without only adds to it. These are the blends the two shapes of `shimmer` have always used.
    func testSuggestedBlendModeFollowsTheBackground() {
        XCTAssertEqual(ShimmerLight(color: color, background: background).suggestedBlendMode, .sourceAtop)
        XCTAssertEqual(ShimmerLight(color: color).suggestedBlendMode, .screen)
    }

    /// HDR is only asked for above zero stops, and an exposure that can't be turned into headroom leaves the light in standard dynamic range rather than drawing something undefined.
    func testOnlyUsableExposureStopsEnableHDR() {
        XCTAssertFalse(ShimmerLight(color: color, exposureStops: 0).isHDREnabled)
        XCTAssertFalse(ShimmerLight(color: color, exposureStops: -1).isHDREnabled)
        XCTAssertFalse(ShimmerLight(color: color, exposureStops: .nan).isHDREnabled)
        XCTAssertFalse(ShimmerLight(color: color, exposureStops: .infinity).isHDREnabled)
        XCTAssertFalse(ShimmerLight(color: color, exposureStops: 10000).isHDREnabled)

        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            XCTAssertTrue(ShimmerLight(color: color, exposureStops: 1).isHDREnabled)
        }
        #endif
    }

    /// The light draws the gradient its own falloff describes, in its own colors.
    func testLightDrawsItsFalloffsGradient() {
        let light = ShimmerLight(color: color, background: background, falloff: .power(2))

        XCTAssertEqual(light.gradient, ShimmerFalloff.power(2).gradient(color: color, background: background))
    }

    /// A linear falloff has to stay the two colour gradient shimmer has always drawn. Sampling it into stops instead would fade opacity, which renders brighter through the midtones.
    func testLinearFalloffIsTheOriginalTwoColorGradient() {
        let stops = ShimmerFalloff.linear.gradient(color: color, background: background).stops

        XCTAssertEqual(stops.count, 2)
        XCTAssertEqual(stops.first?.color, color)
        XCTAssertEqual(stops.first?.location, 0)
        XCTAssertEqual(stops.last?.color, background)
        XCTAssertEqual(stops.last?.location, 1)
    }

    /// An exponent of one is a straight line, so it is the linear falloff rather than a sampled copy of it.
    func testPowerOfOneIsLinear() {
        XCTAssertEqual(ShimmerFalloff.power(1), .linear)
    }

    /// An exponent that can't describe a fade leaves the light looking as it would untouched rather than solid or inverted.
    func testUnusablePowerExponentsAreLinear() {
        XCTAssertEqual(ShimmerFalloff.power(0), .linear)
        XCTAssertEqual(ShimmerFalloff.power(-2), .linear)
        XCTAssertEqual(ShimmerFalloff.power(.nan), .linear)
        XCTAssertEqual(ShimmerFalloff.power(.infinity), .linear)
    }

    /// A curve is sampled into evenly spaced stops running from the full shimmer colour at the centre to nothing at the edge.
    func testPowerFalloffIsSampledFromCentreToEdge() {
        let stops = ShimmerFalloff.power(2).gradient(color: color, background: background).stops

        XCTAssertEqual(stops.count, ShimmerFalloff.segments + 1)
        XCTAssertEqual(stops.first?.color, color)
        XCTAssertEqual(stops.first?.location, 0)
        XCTAssertEqual(stops.last?.color, color.opacity(0))
        XCTAssertEqual(stops.last?.location, 1)

        let locations = stops.map(\.location)
        XCTAssertEqual(locations, locations.sorted())
        XCTAssertEqual(stops[ShimmerFalloff.segments / 2].location, 0.5, accuracy: 0.0001)
    }

    /// The point of raising the exponent is a smaller bright area, so halfway out has to be dimmer than the straight line's half brightness.
    func testHigherPowersAreDimmerHalfwayOut() {
        let midpoint = ShimmerFalloff.segments / 2
        let intensities = [2.0, 3, 4].map { ShimmerFalloff.power($0).intensities?[midpoint] }

        XCTAssertEqual(intensities.compactMap { $0 }.count, 3)
        for intensity in intensities.compactMap({ $0 }) {
            XCTAssertLessThan(intensity, 0.5)
        }
        XCTAssertEqual(zip(intensities, intensities.dropFirst()).allSatisfy { $1! < $0! }, true)
    }

    /// Supplied opacities are spaced evenly from centre to edge, whatever their number.
    func testSuppliedIntensitiesAreSpacedEvenly() {
        let stops = ShimmerFalloff.intensities([1, 0.25, 0]).gradient(color: color, background: background).stops

        XCTAssertEqual(stops.map(\.location), [0, 0.5, 1])
        XCTAssertEqual(stops.map(\.color), [color, color.opacity(0.25), color.opacity(0)])
    }

    /// Opacity only means anything between zero and one, and a value that is no number at all would drop a stop out of the gradient.
    func testSuppliedIntensitiesAreClamped() {
        XCTAssertEqual(ShimmerFalloff.intensities([2, -1, .nan]).intensities, [1, 0, 0])
    }

    /// One opacity leaves nothing to interpolate towards, so there is no fade to draw.
    func testTooFewSuppliedIntensitiesAreLinear() {
        XCTAssertEqual(ShimmerFalloff.intensities([]), .linear)
        XCTAssertEqual(ShimmerFalloff.intensities([0.5]), .linear)
    }

    /// The gradient is squeezed on one axis by as much as it is stretched on the other, so a light ends up as wide relative to its height as its aspect ratio says.
    func testGradientScaleGivesTheAspectRatioAsked() {
        for aspectRatio in [0.25, 0.5, 1, 2, 4] as [CGFloat] {
            let scale = ShimmerLight(color: color, aspectRatio: aspectRatio, scale: 4).gradientScale

            XCTAssertEqual(scale.width / scale.height, aspectRatio, accuracy: 0.0001)
        }
    }

    /// Reshaping a light doesn't change how much of the view it covers, so the scale is free to mean size on its own.
    func testGradientScaleKeepsItsAreaWhateverTheAspectRatio() {
        for aspectRatio in [0.25, 0.5, 1, 2, 4] as [CGFloat] {
            let scale = ShimmerLight(color: color, aspectRatio: aspectRatio, scale: 4).gradientScale

            XCTAssertEqual(scale.width * scale.height, 16, accuracy: 0.0001)
        }
    }

    /// An aspect ratio of one leaves the circular gradient it started as.
    func testAnAspectRatioOfOneIsCircular() {
        XCTAssertEqual(ShimmerLight(color: color, aspectRatio: 1, scale: 4).gradientScale, CGSize(width: 4, height: 4))
    }

    /// A scale or aspect ratio that isn't positive and finite would collapse, flip, or divide by zero, so the gradient is drawn unscaled instead.
    func testUnusableScalesAreDrawnUnscaled() {
        let unscaled = CGSize(width: 1, height: 1)

        XCTAssertEqual(ShimmerLight(color: color, aspectRatio: 0).gradientScale, unscaled)
        XCTAssertEqual(ShimmerLight(color: color, aspectRatio: -1).gradientScale, unscaled)
        XCTAssertEqual(ShimmerLight(color: color, scale: 0).gradientScale, unscaled)
        XCTAssertEqual(ShimmerLight(color: color, scale: .infinity).gradientScale, unscaled)
    }
}
