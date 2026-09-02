//
//  LookingGlassUIExampleView.swift
//  LookingGlassUIExampleView
//
//  Created by Ryan Lintott on 2021-08-04.
//

import LookingGlassUI
import SwiftUI

struct LookingGlassUIExampleView: View {
    @State private var isHDREnabled = true
    @State private var hdrExposureStops = 1.5

    var body: some View {
        Color.clear
            .overlay(
                VStack {
                    Spacer()
                    Link(destination: URL(string: "https://github.com/ryanlintott/LookingGlassUI")!) {
                        Text("LookingGlassUI")
                            .font(.custom("Cochin", size: 40))
                            .fontWeight(.bold)
                            .padding(10)
                            .padding(.horizontal, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 0, style: .circular)
                                    .strokeBorder(lineWidth: 5)
                            )
                    }
                    
                    Spacer()
                    
                    Link(destination: URL(string: "https://mastodon.social/@ryanlintott")!) {
                        Text("By: Ryan Lintott")
                            .font(.custom("Cochin", size: 19))
                            .bold()
                    }
                    
                    Spacer()
                }
            )
            .foregroundColor(.gold)
            .shimmer(
                color: .goldShimmer,
                exposureStops: isHDREnabled ? hdrExposureStops : 0
            )
            .overlay(alignment: .bottom) {
                #if compiler(>=6.2)
                if #available(iOS 26.0, *) {
                    VStack(spacing: 8) {
                        Toggle("HDR Shimmer", isOn: $isHDREnabled)

                        HStack {
                            Text("Exposure")

                            Slider(value: $hdrExposureStops, in: 0...3, step: 0.25)
                                .accessibilityLabel("HDR exposure")
                                .accessibilityValue(
                                    "\(hdrExposureStops, format: .number.precision(.fractionLength(2))) stops"
                                )

                            Text("\(hdrExposureStops, format: .number.precision(.fractionLength(2))) stops")
                                .monospacedDigit()
                                .frame(minWidth: 76, alignment: .trailing)
                        }
                        .disabled(!isHDREnabled)
                    }
                        .padding(12)
                        .frame(maxWidth: 360)
                        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .tint(.gold)
                        .padding()
                }
                #endif
            }
    }
}
struct LookingGlassUIExampleView_Previews: PreviewProvider {
    static var previews: some View {
        LookingGlassUIExampleView()
            .motionManager(preferredUpdateInterval: 0)
    }
}
