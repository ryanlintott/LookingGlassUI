//
//  EnvironmentValues.swift
//  LookingGlassUI
//

import SwiftUI

private struct MotionUpdatesEnabledKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

public extension EnvironmentValues {
    /// Whether motion updates are enabled for the scene containing this view.
    ///
    /// True when the nearest ``SwiftUICore/View/motionManager(updateInterval:disabled:)`` modifier was given a positive `updateInterval` and was not disabled. False when there is no such modifier above this view.
    ///
    /// Every effect in this package draws only while this is true. Read it to match your own views to the built-in ones:
    ///
    /// ```swift
    /// @Environment(\.motionUpdatesEnabled) private var motionUpdatesEnabled
    /// ```
    ///
    /// This describes the configuration a scene asked for, not whether samples are currently arriving. It stays true while the app or the scene is in the background: updates stop there, but effects stay on screen at their last rotation so they're still in the app switcher snapshot.
    internal(set) var motionUpdatesEnabled: Bool {
        get { self[MotionUpdatesEnabledKey.self] }
        set { self[MotionUpdatesEnabledKey.self] = newValue }
    }
}
