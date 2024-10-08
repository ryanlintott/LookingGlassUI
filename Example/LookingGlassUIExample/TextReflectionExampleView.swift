//
//  TextReflectionExampleView.swift
//  ReflectiveUIExample
//
//  Created by Ryan Lintott on 2021-05-10.
//

import LookingGlassUI
import SwiftUI

struct TextReflectionExampleView: View {
    let pitch: Angle
    let yaw: Angle
    let localRoll: Angle
    
    init(pitch: Angle = .zero, yaw: Angle = .zero, localRoll: Angle = .zero) {
        self.pitch = pitch
        self.yaw = yaw
        self.localRoll = localRoll
    }
    
    var body: some View {
        LookingGlass(.reflection, distance: 4000, perspective: 0, pitch: pitch, yaw: yaw, localRoll: localRoll, isShowingInFourDirections: true) {
            Color.gray
                .frame(width: 500, height: 500)
                .fixedSize()
                .overlay(
                    Image(systemName: "lightbulb")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .foregroundColor(.white)
                )
                .overlay(
                    Text("Hello World")
                        .bold()
                        .foregroundColor(.red)
                )
                .scaleEffect(4)
        }
        .allowsHitTesting(false)
    }
}

struct TextReflectionExampleView_Previews: PreviewProvider {
    static var previews: some View {
        TextReflectionExampleView()
    }
}
