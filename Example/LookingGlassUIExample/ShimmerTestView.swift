//
//  ShimmerTestView.swift
//  LookingGlassUIExample
//
//  Created by Ryan Lintott on 2021-05-25.
//

import LookingGlassUI
import SwiftUI

struct ShimmerTestView: View {
    var body: some View {
        VStack {
            ShimmerView(color: .red, background: .blue)
                .overlay(
                    VStack {
                        Text("ShimmerView(color: .red, background: .blue)")
                    }
                        .padding()
                )
                .accessibilityElement(children: .combine)
            
            Capsule().shimmer(color: .red, background: .blue)
                .overlay(
                    Text("Capsule().shimmer(color: .red, background: .blue)")
                        .padding()
                )
                .accessibilityElement(children: .combine)
            
            Capsule().fill(.blue).shimmer(color: .red)
                .overlay(
                    VStack {
                        Text("Capsule().fill(.blue).shimmer(color: .red)")
                        Text("(uses .screen blend mode)")
                    }
                        .padding()
                )
                .accessibilityElement(children: .combine)
            
            Capsule().fill(.blue).shimmer(color: .red, blendMode: .multiply)
                .overlay(
                    Text("Capsule().fill(.blue).shimmer(color: .red, blendMode: .multiply)")
                        .padding()
                )
                .accessibilityElement(children: .combine)
        }
        .foregroundColor(.white)
        .font(.caption)
    }
}

#Preview {
    ShimmerTestView()
        .motionManager(updateInterval: 0)
}
