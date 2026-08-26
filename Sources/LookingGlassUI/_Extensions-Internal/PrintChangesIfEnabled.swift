//
//  PrintChangesIfEnabled.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-24.
//

import SwiftUI

extension View {
    /// Prints the properties that caused this view to update when ``MotionService/isPrintingViewChanges`` is on.
    ///
    /// Call from the top of a view body with `let _ = Self.printChangesIfEnabled()`. Only prints in debug builds.
    @MainActor
    static func printChangesIfEnabled() {
        #if DEBUG
        if MotionService.isPrintingViewChanges {
            Self._printChanges()
        }
        #endif
    }
}

extension ViewModifier {
    /// Prints the properties that caused this view modifier to update when ``MotionService/isPrintingViewChanges`` is on.
    ///
    /// Call from the top of a view modifier body with `let _ = Self.printChangesIfEnabled()`. Only prints in debug builds.
    @MainActor
    static func printChangesIfEnabled() {
        #if DEBUG
        if MotionService.isPrintingViewChanges {
            Self._printChanges()
        }
        #endif
    }
}
