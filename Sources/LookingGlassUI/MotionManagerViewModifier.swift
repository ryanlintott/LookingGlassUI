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

    /// The shared manager whose effective state determines whether this scene can display motion effects.
    @ObservedObject private var motionManager = MotionManager.shared
    
    /// The scene's requested interval between motion samples, in seconds.
    let updateInterval: TimeInterval

    /// Whether this scene has disabled motion updates.
    let disabled: Bool

    /// The persistent identifier for this modifier's request in the shared manager.
    @State private var registrationID = UUID()
    
    func body(content: Content) -> some View {
        let _ = Self.printChangesIfEnabled()
        content
            .environmentObject(motionManager)
            .environmentObject(motionManager.deviceRotation)
            .environment(\.sceneMotionEffectsEnabled, motionManager.motionEffectsEnabled(id: registrationID))
            .onAppear {
                motionManager.registerMotionUpdates(
                    id: registrationID,
                    updateInterval: updateInterval,
                    disabled: disabled,
                    scenePhase: scenePhase
                )
            }
            .onDisappear {
                motionManager.unregisterMotionUpdates(id: registrationID)
            }
            .onChange(of: updateInterval) {
                motionManager.updateMotionUpdates(
                    id: registrationID,
                    updateInterval: $0,
                    disabled: disabled,
                    scenePhase: scenePhase
                )
            }
            .onChange(of: disabled) {
                motionManager.updateMotionUpdates(
                    id: registrationID,
                    updateInterval: updateInterval,
                    disabled: $0,
                    scenePhase: scenePhase
                )
            }
            .onChange(of: scenePhase) {
                motionManager.updateMotionUpdates(
                    id: registrationID,
                    updateInterval: updateInterval,
                    disabled: disabled,
                    scenePhase: $0
                )
            }
    }
}

public extension View {
    /// Adds ``MotionManager`` and ``DeviceRotation`` into the environment.
    /// - Adjusts for landscape/portrait changes to device orientation.
    /// - Suspends a scene's request while that scene is in the background.
    /// - Shares one Core Motion service across scenes. Add this modifier once near the top of each scene's view hierarchy. The fastest enabled foreground scene controls the shared service, and removing, disabling, or backgrounding one scene does not stop another foreground scene's updates.
    ///
    /// - Parameters:
    ///   - updateInterval: Interval between motion updates in seconds. 0 will disable updates, 1/60 is 60fps and will update every frame. Somewhere between 0.1 - 0.2 is a good compromise between reactivity and performance with shimmer effects. Test performance on older devices as fast updates can make a device unusable.
    ///   - disabled: Used to temporarily disable updates.
    /// - Returns: View with ``MotionManager`` and ``DeviceRotation`` in the environment
    func motionManager(updateInterval: TimeInterval = 0.1, disabled: Bool = false) -> some View {
        self.modifier(MotionManagerViewModifier(updateInterval: updateInterval, disabled: disabled))
    }
}
