//
//  QuaternionDataView.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2022-09-01.
//

import SwiftUI

/// A view that lists the components of a quaternion for debugging.
///
/// Shows the axis vector and angle, followed by the pitch, yaw, and roll. Designed to be placed inside a `List` as it uses `Section`.
public struct QuaternionDataView: View {
    let quat: Quat?
    
    public init(_ quat: Quat?) {
        self.quat = quat
    }

    @ViewBuilder
    public var body: some View {
        if let quat {
            Section {
                data("Axis Vector x", quat.axis.x)
                data("Axis Vector y", quat.axis.y)
                data("Axis Vector z", quat.axis.z)
                data("Angle (degrees)", quat.angle.degrees)
            } header: {
                Text("Axis Vector and angle")
            }
            
            Section {
                data("Pitch (degrees)", quat.pitch.degrees)
                data("Yaw (degrees)", quat.yaw.degrees)
                data("Roll (degrees)", quat.roll.degrees)
            } header: {
                Text("Rotation components")
            }
        } else {
            Text("Quat: Nil")
        }
    }
    
    func data(_ label: String, _ value: Double) -> some View {
        Text("\(label): \(value)")
            .accessibilityLabel(label)
            .accessibilityValue(String(value))
            .accessibilityAddTraits(.updatesFrequently)
    }
}
