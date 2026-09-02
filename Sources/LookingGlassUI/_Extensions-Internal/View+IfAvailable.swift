//
//  View+IfAvailable.swift
//  FrameUp
//
//  Created by Ryan Lintott on 2023-07-14.
//

import SwiftUI

extension View {
    /// Applies the given transform or returns the untransformed view.
    ///
    /// Useful for availability branching on view modifiers. Do not branch with any properties that may change during runtime as this will cause errors.
    /// - Parameters:
    ///   - transform: The transform to apply to the source `View`.
    /// - Returns: The view transformed by the transform.
    @ViewBuilder
    nonisolated func ifAvailable(@ViewBuilder _ transform: (Self) -> (some View)?) -> some View {
        if let transformed = transform(self) { transformed } else { self }
    }
}
