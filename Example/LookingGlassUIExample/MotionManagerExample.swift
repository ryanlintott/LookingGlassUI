//
//  MotionManagerExample.swift
//  LookingGlassUIExample
//
//  Created by Ryan Lintott on 2022-03-28.
//

import LookingGlassUI
import SwiftUI

struct MotionManagerExample: View {
    @EnvironmentObject var motionManager: MotionManager
    
    var body: some View {
        List {
            QuaternionDataView(motionManager.quaternion)
        }
            .navigationTitle("MotionManager Data")
    }
}

struct MotionManagerExample_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MotionManagerExample()
                .motionManager(updateInterval: 0)
        }
    }
}
