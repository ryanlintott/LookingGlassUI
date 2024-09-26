//
//  MotionManagerViewModifier.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2021-05-14.
//

import SwiftUI

struct MotionManagerViewModifier: ViewModifier {
    @ObservedObject var motionManager = MotionManager.shared
    
    let updateInterval: TimeInterval
    let disabled: Bool
    
    func body(content: Content) -> some View {
        content
            .environmentObject(motionManager)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                motionManager.changeDeviceOrientation()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                motionManager.startMotionUpdates(updateInterval: updateInterval, disabled: disabled, setDeviceOrientation: true)
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                motionManager.stopMotionUpdates()
            }
            .onAppear {
                motionManager.startMotionUpdates(updateInterval: updateInterval, disabled: disabled, setDeviceOrientation: true)
            }
            .onDisappear {
                motionManager.stopMotionUpdates()
            }
            .onChange(of: updateInterval) {
                motionManager.setUpdateInterval($0)
            }
            .onChange(of: disabled) {
                motionManager.setDisabled($0)
            }
    }
}

public extension View {
    /// Adds ``MotionManager`` into the environment.
    /// - Adjusts for landscape/portrait changes to device orientation.
    /// - Disables and enables with moving to/from background
    ///
    /// - Parameters:
    ///   - updateInterval: Interval between motion updates in seconds. 0 will disable updates, 1/60 is 60fps and will update every frame. Somewhere between 0.1 - 0.2 is a good compromise between reactivity and performance with shimmer effects. Test performance on older devices as fast updates can make a device unusable.
    ///   - disabled: Used to temporarily disable updates.
    /// - Returns: View with ``MotionManager`` in the environment
    func motionManager(updateInterval: TimeInterval = 0.1, disabled: Bool = false) -> some View {
        self.modifier(MotionManagerViewModifier(updateInterval: updateInterval, disabled: disabled))
    }
}
