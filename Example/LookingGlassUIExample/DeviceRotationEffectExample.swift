//
//  DeviceRotationEffectExample.swift
//  LookingGlassUIExample
//
//  Created by Ryan Lintott on 2022-09-01.
//

import LookingGlassUI
import SwiftUI

struct DeviceRotationEffectExample: View {
    @State private var type: DeviceRotationEffectType = .reflection
    @State private var distance: CGFloat = 0
    @State private var perspective: CGFloat = 1
    @State private var pitchDegrees: CGFloat = 0
    @State private var yawDegrees: CGFloat = 0
    @State private var localRollDegrees: CGFloat = 0
    @State private var isShowingInFourDirections: Bool = false
    
    var body: some View {
        VStack {
            ZStack {
                Color.clear
                Text("Hello, World!")
                    .padding()
                    .foregroundColor(.white)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.blue)
                    )
                    .deviceRotationEffect(
                        type,
                        distance: distance,
                        perspective: perspective,
                        pitch: .degrees(pitchDegrees),
                        yaw: .degrees(yawDegrees),
                        localRoll: .degrees(localRollDegrees),
                        isShowingInFourDirections: isShowingInFourDirections
                    )
            }
            
            Picker("Type", selection: $type) {
                ForEach(DeviceRotationEffectType.allCases) { type in
                    Text(type.rawValue.capitalized)
                }
            }
            .pickerStyle(.segmented)
            
            HStack {
                VStack {
                    Text("Distance")
                    Text("\(distance)")
                }
                Slider(value: $distance, in: -100...100)
            }
            HStack {
                VStack {
                    Text("Perspective")
                    Text("\(perspective)")
                }
                Slider(value: $perspective, in: 0...2)
            }
            HStack {
                VStack {
                    Text("Pitch")
                    Text("\(pitchDegrees)")
                }
                Slider(value: $pitchDegrees, in: -180...180)
            }
            HStack {
                VStack {
                    Text("Yaw")
                    Text("\(yawDegrees)")
                }
                Slider(value: $yawDegrees, in: -180...180)
            }
            HStack {
                VStack {
                    Text("Local Roll")
                    Text("\(localRollDegrees)")
                }
                Slider(value: $localRollDegrees, in: -180...180)
            }
            Toggle("Clone x 4", isOn: $isShowingInFourDirections)
        }
        .padding()
    }
}

struct DeviceRotationEffectExample_Previews: PreviewProvider {
    static var previews: some View {
        DeviceRotationEffectExample()
            .motionManager(updateInterval: 0)
    }
}
