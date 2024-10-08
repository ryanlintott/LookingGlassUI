//
//  ContentView.swift
//  LookingGlassUIExample
//
//  Created by Ryan Lintott on 2021-05-18.
//

import LookingGlassUI
import SwiftUI

struct ContentView: View {
    @State private var updateInterval: TimeInterval = 0.1
    @State private var disabled: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            TabView {
                LookingGlassUIExampleView()
                    .tabItem {
                        Image(systemName: "light.max")
                        Text("Logo")
                    }
                
                ShimmerTestView()
                    .tabItem {
                        Image(systemName: "sparkle")
                        Text("ShimmerTest")
                    }
                
                ShimmerExampleView()
                    .tabItem {
                        Image(systemName: "sparkles")
                        Text("Shimmer")
                    }
                
                ParallaxExample()
                    .tabItem {
                        Image(systemName: "rectangle.portrait.on.rectangle.portrait")
                        Text("Parallax")
                    }
                
                Group {
                    DeviceRotationEffectExample()
                        .tabItem {
                            Image(systemName: "arrow.turn.up.forward.iphone")
                            Text("Device")
                        }
                    
                    Color.clear
                        .overlay(
                            ArrowRotationView(.reflection)
                        )
                        .tabItem {
                            Image(systemName: "arrow.up.and.person.rectangle.portrait")
                            Text("Reflection")
                        }
                    
                    Color.clear
                        .overlay(
                            ArrowRotationView(.window)
                        )
                        .tabItem {
                            Image(systemName: "arrow.up.and.person.rectangle.portrait")
                            Text("Window")
                        }
                    
                    Color.clear
                        .overlay(
                            TextReflectionExampleView()
                        )
                        .tabItem {
                            Image(systemName: "arrow.up")
                            Text("0°")
                        }
                    
                    Color.clear
                        .overlay(
                            TextReflectionExampleView(pitch: .degrees(90))
                        )
                        .tabItem {
                            Image(systemName: "arrow.forward")
                            Text("90°")
                        }
                    
                    Color.clear
                        .overlay(
                            TextReflectionExampleView(pitch: .degrees(45))
                        )
                        .tabItem {
                            Image(systemName: "arrow.up.forward")
                            Text("45°")
                        }
                }
                
                
                
                MotionManagerExample()
                    .tabItem {
                        Image(systemName: "rectangle.split.3x3")
                        Text("MotionManager Data")
                    }
            }
            
            SettingsView(updateInterval: $updateInterval, disabled: $disabled)
        }
        .motionManager(updateInterval: updateInterval, disabled: disabled)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .motionManager(updateInterval: 0)
    }
}
