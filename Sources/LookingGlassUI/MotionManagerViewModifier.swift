//
//  MotionManagerViewModifier.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2021-05-14.
//

import SwiftUI

struct MotionManagerViewModifier: ViewModifier {
    /// The lifecycle state of the scene that contains the modified view.
    @Environment(\.scenePhase) private var scenePhase

    /// This scene's manager.
    ///
    /// Owned by SwiftUI, so it's deallocated when the scene's state is destroyed and the shared service loses this scene's claim on it without needing to be told.
    @StateObject private var motionManager: MotionManager

    /// The scene's requested interval between motion samples, in seconds.
    let preferredUpdateInterval: TimeInterval

    /// Whether this scene has disabled motion updates.
    let disabled: Bool

    init(preferredUpdateInterval: TimeInterval, disabled: Bool) {
        self.preferredUpdateInterval = preferredUpdateInterval
        self.disabled = disabled

        /// A scene is active when it's built. Any other phase arrives through `onAppear` or `onChange` before the first motion sample would.
        _motionManager = StateObject(
            wrappedValue: MotionManager(preferredUpdateInterval: preferredUpdateInterval, disabled: disabled, scenePhase: .active)
        )
    }

    func body(content: Content) -> some View {
        let _ = Self.printChangesIfEnabled()
        content
            .environmentObject(motionManager)
            .environmentObject(DeviceMotion.shared)
            .onAppear {
                motionManager.update(preferredUpdateInterval: preferredUpdateInterval, disabled: disabled, scenePhase: scenePhase)
            }
            .onChange(of: preferredUpdateInterval) {
                motionManager.update(preferredUpdateInterval: $0, disabled: disabled, scenePhase: scenePhase)
            }
            .onChange(of: disabled) {
                motionManager.update(preferredUpdateInterval: preferredUpdateInterval, disabled: $0, scenePhase: scenePhase)
            }
            .onChange(of: scenePhase) {
                motionManager.update(preferredUpdateInterval: preferredUpdateInterval, disabled: disabled, scenePhase: $0)
            }
    }
}

public extension View {
    @available(*, unavailable, renamed: "motionManager(preferredUpdateInterval:disabled:)", message: "Renamed because a scene can receive samples faster than it asked for. The fastest enabled foreground scene controls the shared service and `DeviceMotion.updateInterval` reports the rate samples actually arrive at.")
    func motionManager(updateInterval: TimeInterval, disabled: Bool = false) -> some View {
        self.motionManager(preferredUpdateInterval: updateInterval, disabled: disabled)
    }

    /// Adds ``MotionManager`` and ``DeviceMotion`` into the environment.
    /// - Adjusts for landscape/portrait changes to device orientation.
    /// - Suspends a scene's request while that scene is in the background.
    /// - Shares one Core Motion service across scenes. Add this modifier once near the top of each scene's view hierarchy. The fastest enabled foreground scene controls the shared service, and removing, disabling, or backgrounding one scene does not stop another foreground scene's updates.
    ///
    /// - Parameters:
    ///   - preferredUpdateInterval: Interval between motion updates in seconds that this scene asks for. 0 will disable updates, 1/60 is 60fps and will update every frame. The default of 0.1 is usally a good compromise between reactivity and performance for shimmer, parallax and other rotation-based effects. Test performance on older devices as fast updates can make a device unusable. Samples can arrive faster than this as every scene shares one service running at the fastest requested interval. ``DeviceMotion/updateInterval`` reports the rate they actually arrive at.
    ///   - disabled: Used to temporarily disable updates.
    /// - Returns: View with ``MotionManager`` and ``DeviceMotion`` in the environment.
    func motionManager(preferredUpdateInterval: TimeInterval = 0.1, disabled: Bool = false) -> some View {
        self.modifier(MotionManagerViewModifier(preferredUpdateInterval: preferredUpdateInterval, disabled: disabled))
    }
}
