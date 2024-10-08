//
//  ArrowRotationView.swift
//  ReflectiveUIExample
//
//  Created by Ryan Lintott on 2021-05-13.
//

import LookingGlassUI
import SwiftUI

struct ArrowRotationView: View {
    let type: DeviceRotationEffectType
    
    init(_ type: DeviceRotationEffectType) {
        self.type = type
    }
    
    var body: some View {
        Color.clear
            .overlay(
                LookingGlass(type, distance: 10, perspective: 1, pitch: .degrees(45), yaw: .zero, localRoll: .zero, isShowingInFourDirections: true) {
                    Color.gray
                        .frame(width: 100, height: 100)
                        .fixedSize()
                        .overlay(
                            Image(systemName: "arrow.up.and.person.rectangle.portrait")
                                .resizable()
                                .scaledToFit()
                                .padding()
                                .foregroundColor(.white)
                        )
                }
            )
            .overlay(
                Color.blue.opacity(0.3)
                    .frame(width: 100, height: 100)
            )
    }
}

struct ArrowRotationView_Previews: PreviewProvider {
    static var previews: some View {
        ArrowRotationView(.reflection)
            .motionManager(updateInterval: 0)
    }
}
