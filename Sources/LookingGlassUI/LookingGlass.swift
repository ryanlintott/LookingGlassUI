//
//  LookingGlass.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2021-05-14.
//

import CoreMotion
import SwiftUI

/// A view that rotates another view so it appears locked to real-world orientations. Useful if you want a view that is only visible when the phone is pointed in a specific direction.
///
/// This view will take all proposed space similar to `GeometryReader`. The content view will always be aligned to the centre of the frame ``motionManager(preferredUpdateInterval:disabled:)`` was applied to, regardless of where this view is on the screen or inside a scrollview.
///
/// If motion updates are off the content will not be shown.
/// 
/// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy. Ideally at the top of the view heirarchy so it is effectively the size of the entire window.
public struct LookingGlass<Content: View>: View {
    @EnvironmentObject private var motionManager: MotionManager

    let type: DeviceRotationEffectType
    let distance: CGFloat?
    let perspective: CGFloat?
    let offsetRotation: Quat?
    let isShowingInFourDirections: Bool?
    let content: Content
    
    /// A view that rotates another view so it appears locked to real-world orientations. Useful if you want a view that is only visible when the phone is pointed in a specific direction.
    ///
    /// This view will take all proposed space similar to `GeometryReader`. The content view will always be aligned to the centre of the frame ``motionManager(preferredUpdateInterval:disabled:)`` was applied to, regardless of where this view is on the screen or inside a scrollview.
    ///
    /// If motion updates are off the content will not be shown.
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy. Ideally at the top of the view heirarchy so it is effectively the size of the entire window.
    /// - Parameters:
    ///   - type: Device rotation effect.
    ///   - distance: Distance the view is positioned from the device in points.
    ///   - perspective: Amount of perspective used in the view projection. (default of zero creates an orthographic projection where the view will not decrease in size based on distance)
    ///   - offsetRotation: Quaternion that represents the view's position in the real world. (zero positions the view on the ground.)
    ///   - isShowingInFourDirections: If active the view will be rotated around the Z axis at 90 degree intervals to always face the direction the device is pointing.
    ///   - content: View to be shown.
    public init(
        _ type: DeviceRotationEffectType,
        distance: CGFloat? = nil,
        perspective: CGFloat? = nil,
        offsetRotation: Quat? = nil,
        isShowingInFourDirections: Bool? = nil,
        content: () -> Content
    ) {
        self.type = type
        self.distance = distance
        self.perspective = perspective
        self.offsetRotation = offsetRotation
        self.isShowingInFourDirections = isShowingInFourDirections
        self.content = content()
    }
    
    /// A view that rotates another view so it appears locked to real-world orientations. Useful if you want a view that is only visible when the phone is pointed in a specific direction.
    ///
    /// This view will take all proposed space similar to `GeometryReader`. The content view will always be aligned to the centre of the frame ``motionManager(preferredUpdateInterval:disabled:)`` was applied to, regardless of where this view is on the screen or inside a scrollview.
    ///
    /// If motion updates are off the content will not be shown.
    ///
    /// - Requires: ``motionManager(preferredUpdateInterval:disabled:)`` must be added above this view in the hierarchy. Ideally at the top of the view heirarchy so it is effectively the size of the entire window.
    ///
    /// - Parameters:
    ///   - type: Device rotation effect.
    ///   - distance: Distance the view is positioned from the device in points.
    ///   - perspective: Amount of perspective used in the view projection. (default of zero creates an orthographic projection where the view will not decrease in size based on distance)
    ///   - pitch: The pitch rotation applied to the view relative to the real world.
    ///   - yaw: The yaw rotation applied to the view relative to the real world.
    ///   - localRoll: The local roll applied to the view.
    ///   - isShowingInFourDirections: If active the view will be rotated around the Z axis at 90 degree intervals to always face the direction the device is pointing.
    ///   - content: View to be shown.
    public init(
        _ type: DeviceRotationEffectType,
        distance: CGFloat,
        perspective: CGFloat? = nil,
        pitch: Angle? = nil,
        yaw: Angle? = nil,
        localRoll: Angle? = nil,
        isShowingInFourDirections: Bool? = nil,
        content: () -> Content
    ) {
        self.init(
            type,
            distance: distance,
            perspective: perspective,
            offsetRotation: Quat(pitch: pitch, yaw: yaw, localRoll: localRoll),
            isShowingInFourDirections: isShowingInFourDirections,
            content: content
        )
    }
    
    public var body: some View {
        let _ = Self.printChangesIfEnabled()
        if motionManager.isDetectingMotion, let containerFrame = motionManager.containerFrame {
            GeometryReader { proxy in
                let viewFrame = proxy.frame(in: .global)
                content
                    .deviceRotationEffect(type, distance: distance, perspective: perspective, offsetRotation: offsetRotation, isShowingInFourDirections: isShowingInFourDirections)
                    /// Sized to the container and moved to sit on it, wherever this view happens to be, so the content's centre lands on the centre of the container and every effect in it turns about that one point.
                    .frame(width: containerFrame.width, height: containerFrame.height)
                    .offset(x: containerFrame.minX - viewFrame.minX, y: containerFrame.minY - viewFrame.minY)
            }
        } else {
            Color.clear
        }
    }
}
