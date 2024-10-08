//
//  ShimmerExampleView.swift
//  ReflectiveUIExample
//
//  Created by Ryan Lintott on 2021-05-11.
//

import LookingGlassUI
import SwiftUI

struct ShimmerExampleView: View {
    
    func mode(number: Int) -> ShimmerMode {
        switch number % 4 {
        case 0:
            return .off
        case 1:
            return .on
        case 2:
            return .darkModeOnly
        default:
            return .lightModeOnly
        }
    }
    
    func text(number: Int) -> String {
        switch number % 4 {
        case 0:
            return "Gold \(number): OFF"
        case 1:
            return "Gold \(number): ON"
        case 2:
            return "Gold \(number): DarkOnly"
        default:
            return "Gold \(number): LightOnly"
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(0..<100, id: \.self) { i in
                    VStack {
                        Rectangle()
                            .frame(height: 4)
                        
                        Text(text(number: i))
                            .font(.system(size: 48))
                            .fontWeight(.bold)
                            .padding()
                    }
                    .foregroundColor(.goldDark)
                    .shimmer(mode: mode(number: i), color: .goldShimmer)
                }
            }
        }
    }
}

struct ShimmerExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ShimmerExampleView()
            .motionManager(updateInterval: 0)
    }
}
