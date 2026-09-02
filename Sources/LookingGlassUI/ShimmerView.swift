//
//  ShimmerView.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2021-05-25.
//

import SwiftUI

/// An elliptical gradient that rotates in 3D space based on device orientation
///
/// Takes all available space similar to `Color`
public struct ShimmerView: View {
    @EnvironmentObject private var motionManager: MotionManager
    @Environment(\.colorScheme) var colorScheme
    
    let mode: ShimmerMode
    let color: Color
    let background: Color
    let exposureStops: Double

    let startRadius: CGFloat = 5
    let endRadius: CGFloat = 125
    let scale: CGFloat = 5
    let aspectRatio: CGFloat = 0.5
    let distance: CGFloat = 4000
    let pitch: Angle = .degrees(45)
    let yaw: Angle = .zero
    let localRoll: Angle = .degrees(-30)
    
    /// Creates a shimmering view based on device orientation
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Parameters:
    ///   - mode: Modes where shimmer should be enabled. (default: `.on`)
    ///   - color: Shimmer color
    ///   - background: Background color
    ///   - exposureStops: HDR exposure applied to the shimmer color on iOS 26 and later. Each stop doubles its brightness. Values that aren't positive and finite use standard dynamic range. (default: `0`)
    public init(mode: ShimmerMode? = nil, color: Color, background: Color, exposureStops: Double = 0) {
        self.mode = mode ?? .on
        self.color = color
        self.background = background
        self.exposureStops = exposureStops
    }
    
    /// Creates a shimmering view based on device orientation
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy.
    ///
    /// - Parameters:
    ///   - isOn: Is shimmer enabled.
    ///   - color: Shimmer color
    ///   - background: Background color
    ///   - exposureStops: HDR exposure applied to the shimmer color on iOS 26 and later. Each stop doubles its brightness. Values that aren't positive and finite use standard dynamic range. (default: `0`)
    public init(isOn: Bool, color: Color, background: Color, exposureStops: Double = 0) {
        self.init(mode: isOn ? .on : .off, color: color, background: background, exposureStops: exposureStops)
    }
    
    var isShimmering: Bool {
        motionManager.isDetectingMotion && mode.isOn(colorScheme: colorScheme)
    }
    
    private var hdrHeadroom: Double? {
        guard exposureStops.isFinite, exposureStops > 0 else { return nil }
        let headroom = pow(2, exposureStops)
        return headroom.isFinite ? headroom : nil
    }

    private var shimmerColor: Color {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *), let hdrHeadroom {
            return color
                .exposureAdjust(exposureStops)
                .headroom(hdrHeadroom)
        }
        #endif
        return color

    }

    private var isHDREnabled: Bool {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            return hdrHeadroom != nil
        }
        #endif
        return false
    }

    
    
    public var body: some View {
        let _ = Self.printChangesIfEnabled()
        background
            .overlay {
                VStack {
                    if isShimmering {
                        LookingGlass(
                            .reflection,
                            distance: distance,
                            perspective: 0,
                            pitch: pitch,
                            yaw: yaw,
                            localRoll: localRoll,
                            isShowingInFourDirections: true
                        ) {
                            RadialGradient(gradient: Gradient(colors: [shimmerColor, background]), center: .center, startRadius: startRadius, endRadius: endRadius)
                                .frame(width: endRadius * 2, height: endRadius * 2)
                                .scaleEffect(x: scale * aspectRatio, y: scale / aspectRatio, anchor: .center)
                        }
                        .clipped()
                        
                    }
                }
                /// This ensures the shimmering effect does not change the content shape for hit testing and accessibility purporses.
                .contentShape(EmptyShape())
            }
            .ifAvailable {
                /// Even though allowed dynamic range is available in iOS 17, we only use it in iOS 26+ so no point enabling it in lower versions.
                if #available(iOS 26.0, *) {
                    $0.transformEnvironment(\.allowedDynamicRange) { allowedDynamicRange in
                        if isHDREnabled {
                            /// Dynamic range is only set if HDR is on and is untouched otherwise
                            allowedDynamicRange = .constrainedHigh
                        }
                    }
                }
            }
    }
}
