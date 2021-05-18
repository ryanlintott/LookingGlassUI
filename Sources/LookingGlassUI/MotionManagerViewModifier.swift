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
    
    @Binding var updateInterval: TimeInterval
    @Binding var disabled: Bool
    
    func body(content: Content) -> some View {
        content
            .environmentObject(motionManager)
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                motionManager.changeDeviceOrientation()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                motionManager.changeDeviceOrientation()
            }
            .onAppear {
                motionManager.changeDeviceOrientation()
                motionManager.setUpdateInterval(updateInterval)
                motionManager.setDisabled(disabled)
            }
            .onChange(of: updateInterval, perform: motionManager.setUpdateInterval)
            .onChange(of: disabled, perform: motionManager.setDisabled)
            .onChange(of: motionManager.updateInterval) {
                if updateInterval != $0 {
                    updateInterval = $0
                }
            }
            .onChange(of: motionManager.disabled) {
                if disabled != $0 {
                    disabled = $0
                }
            }
    }
}

@available (iOS 14, *)
public extension View {
    func motionManager(updateInterval: Binding<TimeInterval>, disabled: Binding<Bool> = .constant(false)) -> some View {
        self.modifier(MotionManagerViewModifier(updateInterval: updateInterval, disabled: disabled))
    }
}
