//
//  ParallaxExample.swift
//  LookingGlassUIExample
//
//  Created by Ryan Lintott on 2022-03-23.
//

import LookingGlassUI
import SwiftUI

struct ParallaxExample: View {
    @State private var multiplier = 100.0
    @State private var maxOffset = 50.0
    
    let shape = RoundedRectangle(cornerRadius: 20)
    
    var body: some View {
        VStack {
            Spacer()
            
            shape
                .stroke(.red)
                .background(
                    shape
                        .fill(.blue)
                        .accessibilityLabel("Blue rectangle")
                        .parallax(multiplier: multiplier, maxOffset: maxOffset)
                )
                .frame(width: 100, height: 200)

            Spacer()
            
            VStack {
                HStack {
                    Text("Multiplier")
                    
                    Slider(value: $multiplier, in: 0...200)
                        .padding(.horizontal)
                }
                
                HStack {
                    Text("Max Offset")
                    
                    Slider(value: $maxOffset, in: 0...100)
                        .padding(.horizontal)
                }
            }
            .padding(.horizontal)
            
        }
    }
}

struct ParallaxExample_Previews: PreviewProvider {
    static var previews: some View {
        ParallaxExample()
            .motionManager(updateInterval: 0)
    }
}
