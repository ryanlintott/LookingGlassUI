//
//  View+rotation3dEffect.swift
//  ReflectiveUI
//
//  Created by Ryan Lintott on 2021-05-13.
//

import SwiftUI

extension View {
    
    /// Rotates this view’s rendered output in three dimensions using a quaternion.
    /// - Parameters:
    ///   - quaternion: The quaternion used to rotate the view.
    ///   - anchor: The location with a default of center that defines a point in 3D space about which the rotation is anchored.
    ///   - anchorZ: The location with a default of 0 that defines a point in 3D space about which the rotation is anchored.
    ///   - perspective: The relative vanishing point with a default of 1 for this rotation.
    /// - Returns: A 3D rotated version of this view.
    public func rotation3dEffect(quaternion: Quat, anchor: UnitPoint, anchorZ: CGFloat, perspective: CGFloat) -> some View {
        self
            .rotation3DEffect(
                quaternion.angle,
                axis: quaternion.axis.cgFloat,
                anchor: anchor,
                anchorZ: anchorZ,
                perspective: perspective
            )
    }
}
