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

    /// How bright a sampled falloff is halfway from where its fade starts to the outer edge, whatever it was sampled into.
    private func intensityHalfwayOut(_ falloff: ShimmerFalloff) -> Double? {
        guard let intensities = falloff.intensities else { return nil }
        return intensities[(intensities.count - 1) / 2]
    }

    /// The values that were fixed inside `ShimmerView` before there was a light to pass it. Changing any of these changes how every existing shimmer looks.
    func testDefaultsMatchTheValuesTheyReplaced() {
        let light = ShimmerLight(color: color, background: background)

        XCTAssertEqual(light.exposureStops, 0)
        XCTAssertEqual(light.size, CGSize(width: 625, height: 2500))
        XCTAssertEqual(light.distance, 4000)
        XCTAssertEqual(light.pitch, .degrees(45))
        XCTAssertEqual(light.yaw, .zero)
        XCTAssertEqual(light.localRoll, .degrees(-30))
        XCTAssertEqual(light.resolution, 0.2)
        XCTAssertEqual(light.falloff, .linear())
        XCTAssertEqual(light.falloff.core, 0.04)
        XCTAssertEqual(light.aspectRatio, 0.25)
        XCTAssertFalse(light.isHDREnabled)
    }

    /// The gradient `ShimmerView` drew when all of this was fixed inside it: a 250 point circle with a 5 point core, stretched wide and tall.
    func testDefaultsDrawTheGradientShimmerAlwaysDrew() {
        let light = ShimmerLight(color: color, background: background)

        XCTAssertEqual(light.gradientDiameter, 250)
        XCTAssertEqual(light.gradientRadius, 125)
        XCTAssertEqual(light.gradientCoreRadius, 5)
        XCTAssertEqual(light.gradientScale, CGSize(width: 2.5, height: 10))
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
        let stops = ShimmerFalloff.linear().gradient(color: color, background: background).stops

        XCTAssertEqual(stops.count, 2)
        XCTAssertEqual(stops.first?.color, color)
        XCTAssertEqual(stops.first?.location, 0)
        XCTAssertEqual(stops.last?.color, background)
        XCTAssertEqual(stops.last?.location, 1)
    }

    /// An exponent of one is a straight line, so it is the linear falloff rather than a sampled copy of it.
    func testPowerOfOneIsLinear() {
        XCTAssertEqual(ShimmerFalloff.power(1), .linear())
    }

    /// An exponent that can't describe a fade leaves the light looking as it would untouched rather than solid or inverted.
    func testUnusablePowerExponentsAreLinear() {
        XCTAssertEqual(ShimmerFalloff.power(0), .linear())
        XCTAssertEqual(ShimmerFalloff.power(-2), .linear())
        XCTAssertEqual(ShimmerFalloff.power(.nan), .linear())
        XCTAssertEqual(ShimmerFalloff.power(.infinity), .linear())
    }

    /// A curve is sampled into evenly spaced stops running from the full shimmer colour at the centre to nothing at the edge.
    func testPowerFalloffIsSampledFromCentreToEdge() {
        let stops = ShimmerFalloff.power(2).gradient(color: color, background: background).stops

        XCTAssertGreaterThan(stops.count, 2)
        XCTAssertEqual(stops.first?.color, color)
        XCTAssertEqual(stops.first?.location, 0)
        XCTAssertEqual(stops.last?.color, color.opacity(0))
        XCTAssertEqual(stops.last?.location, 1)

        let locations = stops.map(\.location)
        XCTAssertEqual(locations, locations.sorted())
        XCTAssertEqual(locations.map { $0 - locations[0] }.max(), 1)
    }

    /// The point of raising the exponent is a smaller bright area, so halfway out has to be dimmer than the straight line's half brightness.
    func testHigherPowersAreDimmerHalfwayOut() {
        let intensities = [2.0, 3, 4].map { intensityHalfwayOut(ShimmerFalloff.power($0)) }

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
        XCTAssertEqual(ShimmerFalloff.intensities([]), .linear())
        XCTAssertEqual(ShimmerFalloff.intensities([0.5]), .linear())
    }

    /// However small the gradient is drawn, stretching it back up leaves the light the size it was asked for.
    func testTheLightEndsUpTheSizeItWasGiven() {
        let sizes = [CGSize(width: 625, height: 2500), CGSize(width: 300, height: 300), CGSize(width: 900, height: 100)]

        for size in sizes {
            for resolution in [0.05, 0.2, 1, 2] as [CGFloat] {
                let light = ShimmerLight(color: color, size: size, resolution: resolution)

                XCTAssertEqual(light.gradientDiameter * light.gradientScale.width, size.width, accuracy: 0.0001)
                XCTAssertEqual(light.gradientDiameter * light.gradientScale.height, size.height, accuracy: 0.0001)
            }
        }
    }

    /// The aspect ratio is read off the size rather than set alongside it, so the two can't disagree.
    func testAspectRatioIsDerivedFromTheSize() {
        XCTAssertEqual(ShimmerLight(color: color, size: CGSize(width: 100, height: 400)).aspectRatio, 0.25)
        XCTAssertEqual(ShimmerLight(color: color, size: CGSize(width: 300, height: 300)).aspectRatio, 1)
        XCTAssertEqual(ShimmerLight(color: color, size: CGSize(width: 900, height: 100)).aspectRatio, 9)
    }

    /// A square light is drawn as the circle it already is, with nothing to stretch.
    func testASquareLightIsNotStretched() {
        let scale = ShimmerLight(color: color, size: CGSize(width: 300, height: 300)).gradientScale

        XCTAssertEqual(scale.width, scale.height)
    }

    /// Resolution changes how much is drawn, not how big the result is, and one draws the light at full size.
    func testResolutionOnlyChangesHowMuchIsDrawn() {
        let low = ShimmerLight(color: color, resolution: 0.1)
        let high = ShimmerLight(color: color, resolution: 0.5)
        let full = ShimmerLight(color: color, size: CGSize(width: 300, height: 300), resolution: 1)

        XCTAssertLessThan(low.gradientDiameter, high.gradientDiameter)
        XCTAssertEqual(low.size, high.size)
        XCTAssertEqual(full.gradientDiameter, 300)
        XCTAssertEqual(full.gradientScale, CGSize(width: 1, height: 1))
    }

    /// A resolution that would draw nothing at all falls back to drawing the light at full size, which still looks right and only costs more.
    func testUnusableResolutionsDrawAtFullSize() {
        for resolution in [0, -1, CGFloat.nan, .infinity] as [CGFloat] {
            let light = ShimmerLight(color: color, size: CGSize(width: 300, height: 300), resolution: resolution)

            XCTAssertEqual(light.gradientDiameter, 300)
        }
    }

    /// The falloff's core is a fraction of the radius rather than a length, so it stays where it is however the light is sized or drawn.
    func testCoreIsAFractionOfTheDrawnRadius() {
        XCTAssertEqual(ShimmerLight(color: color, falloff: .linear(core: 0.5)).gradientCoreRadius, 62.5)
        XCTAssertEqual(ShimmerLight(color: color, resolution: 1, falloff: .linear(core: 0)).gradientCoreRadius, 0)
        XCTAssertEqual(ShimmerLight(color: color, resolution: 1, falloff: .linear(core: 0.5)).gradientCoreRadius, 312.5)
    }

    /// A core outside zero to one has no meaning, and one that is no number at all would leave the gradient undrawable.
    func testUnusableCoresAreClamped() {
        XCTAssertEqual(ShimmerLight(color: color, falloff: .linear(core: 2)).gradientCoreRadius, 125)
        XCTAssertEqual(ShimmerLight(color: color, falloff: .linear(core: -1)).gradientCoreRadius, 0)
        XCTAssertEqual(ShimmerLight(color: color, falloff: .linear(core: .nan)).gradientCoreRadius, 0)
    }

    /// Every falloff carries a core, and the curved ones keep the one they were given rather than the shape resetting it.
    func testEveryFalloffCarriesACore() {
        XCTAssertEqual(ShimmerFalloff.power(3).core, 0.04)
        XCTAssertEqual(ShimmerFalloff.power(3, core: 0.2).core, 0.2)
        XCTAssertEqual(ShimmerFalloff.intensities([1, 0]).core, 0.04)
        XCTAssertEqual(ShimmerFalloff.intensities([1, 0], core: 0.2).core, 0.2)
        XCTAssertEqual(ShimmerFalloff.linear(core: 0.2).core, 0.2)
    }

    /// An exponent of one is a straight line whatever core it was given, so the core survives falling back to linear.
    func testFallingBackToLinearKeepsTheCore() {
        XCTAssertEqual(ShimmerFalloff.power(1, core: 0.2), .linear(core: 0.2))
        XCTAssertEqual(ShimmerFalloff.power(.nan, core: 0.2), .linear(core: 0.2))
        XCTAssertEqual(ShimmerFalloff.intensities([0.5], core: 0.2), .linear(core: 0.2))
    }

    /// Two falloffs that fade the same way but hold different cores are different shapes.
    func testCoreCountsTowardsEquality() {
        XCTAssertNotEqual(ShimmerFalloff.linear(core: 0.1), ShimmerFalloff.linear(core: 0.2))
        XCTAssertNotEqual(ShimmerFalloff.power(3, core: 0.1), ShimmerFalloff.power(3, core: 0.2))
    }

    /// A size that isn't positive and finite is no light at all, so nothing is drawn rather than something undefined.
    func testUnusableSizesDrawNothing() {
        let sizes = [
            CGSize(width: 0, height: 100),
            CGSize(width: 100, height: 0),
            CGSize(width: -100, height: 100),
            CGSize(width: CGFloat.nan, height: 100),
            CGSize(width: 100, height: CGFloat.infinity),
        ]

        for size in sizes {
            let light = ShimmerLight(color: color, size: size)

            XCTAssertEqual(light.gradientDiameter, 0)
            XCTAssertEqual(light.gradientScale, CGSize(width: 1, height: 1))
        }
    }
}
