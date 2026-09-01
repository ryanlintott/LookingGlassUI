//
//  SettingsView.swift
//  ReflectiveUIExample
//
//  Created by Ryan Lintott on 2021-05-11.
//

import SwiftUI

struct SettingsView: View {
    @Binding private var preferredUpdateInterval: TimeInterval
    @Binding private var disabled: Bool
    
    static let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumSignificantDigits = 2
        return formatter
    }()
    
    var preferredUpdateIntervalString: String {
        String(format: "Update Interval: %.2f", preferredUpdateInterval)
    }
    
    init(preferredUpdateInterval: Binding<TimeInterval>, disabled: Binding<Bool>) {
        self._preferredUpdateInterval = preferredUpdateInterval
        self._disabled = disabled
    }
    
    var body: some View {
        HStack {
            Stepper(preferredUpdateIntervalString, value: $preferredUpdateInterval, in: 0...1, step: 0.01)
            
            Toggle("Disabled", isOn: $disabled)
                .labelsHidden()
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(preferredUpdateInterval: .constant(0.1), disabled: .constant(false))
    }
}
