//
//  SwiftUIView.swift
//  
//
//  Created by Ryan Lintott on 2021-05-14.
//

import SwiftUI

struct MotionManagerViewModifier: ViewModifier {
    @StateObject var motionManager = MotionManager()
    
    let updateInterval: TimeInterval
    let disabled: Bool
    
    func body(content: Content) -> some View {
        content
            .environmentObject(motionManager)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                motionManager.changeDeviceOrientation()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                motionManager.changeDeviceOrientation()
                motionManager.restart()
            }
            .onAppear {
                motionManager.changeDeviceOrientation()
                motionManager.setUpdateInterval(updateInterval)
                motionManager.setDisabled(disabled)
            }
            .onChange(of: updateInterval, perform: motionManager.setUpdateInterval)
            .onChange(of: disabled, perform: motionManager.setDisabled)
    }
}

public extension View {
    /// Adds `MotionManager` into the environment.
    /// - Adjusts for landscape/portrait changes to device orientation.
    /// - Disables and enables with moving to/from background
    ///
    /// - Parameters:
    ///   - updateInterval: Interval between motion updates in seconds. 0 will disable updates, 1/60 is 60fps and will update every frame. Somewhere between 0.1 - 0.2 is a good compromise between reactivity and performance with shimmer effects. Test performance on older devices as fast updates can make a device unusable.
    ///   - disabled: Used to temporarily disable updates.
    /// - Returns: View with `MotionManager` in the environment
    func motionManager(updateInterval: TimeInterval, disabled: Bool = false) -> some View {
        self.modifier(MotionManagerViewModifier(updateInterval: updateInterval, disabled: disabled))
    }
}
