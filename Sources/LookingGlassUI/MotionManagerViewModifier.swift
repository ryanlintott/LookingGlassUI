//
//  SwiftUIView.swift
//  
//
//  Created by Ryan Lintott on 2021-05-14.
//

import SwiftUI

@available (iOS 14, *)
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
    }
}

@available (iOS 14, *)
public extension View {
    func motionManager(updateInterval: TimeInterval, disabled: Bool = false) -> some View {
        self.modifier(MotionManagerViewModifier(updateInterval: updateInterval, disabled: disabled))
    }
}
