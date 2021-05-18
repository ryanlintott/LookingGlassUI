//
//  Rotation3dEffect-extension.swift
//  ReflectiveUI
//
//  Created by Ryan Lintott on 2021-05-13.
//

import FirebladeMath
import SwiftUI

@available(iOS 14, *)
extension View {
    func rotation3dEffect(quaternion: Quat4f, anchor: UnitPoint, anchorZ: CGFloat, perspective: CGFloat) -> some View {
        self
            .rotation3DEffect(
                quaternion.rotationAngle.angle,
                axis: quaternion.axis.cgFloat,
                anchor: anchor,
                anchorZ: anchorZ,
                perspective: perspective
            )
    }
}
