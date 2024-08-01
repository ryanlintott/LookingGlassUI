//
//  EmptyShape.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2023-09-06.
//

import SwiftUI

/// An empty shape used in the contentShape modifier to create an empty contentShape. This is useful for visible view that you don't want effecting accessibility frames.
struct EmptyShape: InsettableShape {
    nonisolated init() { }
    
    func path(in rect: CGRect) -> Path {
        Path()
    }
    
    nonisolated func inset(by amount: CGFloat) -> EmptyShape {
        EmptyShape()
    }
}
