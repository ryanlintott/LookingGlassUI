//
//  LookingGlassUIExampleView.swift
//  LookingGlassUIExampleView
//
//  Created by Ryan Lintott on 2021-08-04.
//

import LookingGlassUI
import SwiftUI

struct LookingGlassUIExampleView: View {
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
            .shimmer(color: .goldShimmer)
            .background(Color.black.ignoresSafeArea(edges: .top))
    }
}
struct LookingGlassUIExampleView_Previews: PreviewProvider {
    static var previews: some View {
        LookingGlassUIExampleView()
            .motionManager(updateInterval: 0)
    }
}
