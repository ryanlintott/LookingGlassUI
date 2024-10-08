//
//  SettingsView.swift
//  ReflectiveUIExample
//
//  Created by Ryan Lintott on 2021-05-11.
//

import SwiftUI

struct SettingsView: View {
    @Binding private var updateInterval: TimeInterval
    @Binding private var disabled: Bool
    
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumSignificantDigits = 2
        return formatter
    }()
    
    var updateIntervalString: String {
        String(format: "Update Interval: %.2f", updateInterval)
    }
    
    init(updateInterval: Binding<TimeInterval>, disabled: Binding<Bool>) {
        self._updateInterval = updateInterval
        self._disabled = disabled
    }
    
    var body: some View {
        VStack {
            Stepper(updateIntervalString, value: $updateInterval, in: 0...1, step: 0.01)
//            Slider(value: $updateInterval, in: 0...1)
            
            Toggle("Disabled", isOn: $disabled)
//            Toggle("Motion", isOn: $isMotionOn)
//                .onChange(of: isMotionOn) { isMotionOn in
//                    motionManager.updateInterval = isMotionOn ? 0.1 : 0
//                }
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(updateInterval: .constant(0.1), disabled: .constant(false))
    }
}
