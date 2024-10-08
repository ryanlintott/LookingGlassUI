//
//  QuaternionDataView.swift
//  LookingGlassUIExample
//
//  Created by Ryan Lintott on 2022-09-01.
//

import SwiftUI

struct QuaternionDataView: View {
    let quat: Quat
    
    init(_ quat: Quat) {
        self.quat = quat
    }

    var body: some View {
        List {
            Section(header: Text("Axis Vector and angle")) {
                data("Axis Vector x", quat.axis.x)
                data("Axis Vector y", quat.axis.y)
                data("Axis Vector z", quat.axis.z)
                data("Angle (degrees)", quat.rotationAngle.degrees)
            }
            
            Section(header: Text("Rotation components")) {
                data("Pitch (degrees)", quat.pitch.degrees)
                data("Yaw (degrees)", quat.yaw.degrees)
                data("Roll (degrees)", quat.roll.degrees)
            }
        }
    }
    
    func data(_ label: String, _ value: Double) -> some View {
        Text("\(label): \(value)")
            .accessibilityLabel(label)
            .accessibilityValue(String(value))
            .accessibilityAddTraits(.updatesFrequently)
    }
}

struct QuaternionDataView_Previews: PreviewProvider {
    static var previews: some View {
        QuaternionDataView(.identity)
    }
}
