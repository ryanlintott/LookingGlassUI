//
//  DeltaRotationExample.swift
//  LookingGlassUIExample
//
//  Created by Ryan Lintott on 2026-08-27.
//

import LookingGlassUI
import SwiftUI

/// Applies `DeviceMotion.deltaRotation` directly to a view so the object turns with the device, about the screen's own axes, from wherever the device was when updates started.
struct DeltaRotationExample: View {
    @EnvironmentObject private var motionManager: MotionManager
    @EnvironmentObject private var deviceMotion: DeviceMotion

    @State private var distance: CGFloat = 0
    @State private var perspective: CGFloat = 1
    @State private var invert: Bool = false

    var rotation: Quat {
        if invert {
            deviceMotion.deltaRotation.inverse
        } else {
            deviceMotion.deltaRotation
        }
    }

    var body: some View {
        VStack {
            ZStack {
                Color.clear

                if motionManager.isDetectingMotion {
                    Text("Hello, World!")
                        .padding()
                        .foregroundColor(.white)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.blue)
                        )
                        .rotation3DEffect(
                            quaternion: rotation,
                            anchor: .center,
                            anchorZ: distance,
                            perspective: perspective
                        )
                        /// Animated on the device rotation so movement between motion updates is smoothed.
                        .animation(deviceMotion.animation, value: deviceMotion.currentDeviceRotation)
                }
            }
            
            Toggle("Invert", isOn: $invert)

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
        }
        .padding()
    }
}

struct DeltaRotationExample_Previews: PreviewProvider {
    static var previews: some View {
        DeltaRotationExample()
            .motionManager(disabled: true)
    }
}
