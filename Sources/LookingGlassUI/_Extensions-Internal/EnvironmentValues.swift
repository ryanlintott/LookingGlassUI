//
//  EnvironmentValues.swift
//  LookingGlassUI
//

import SwiftUI

extension EnvironmentValues {
    /// Whether motion effects can currently run in the scene hierarchy containing the view.
    ///
    /// This combines the `updateInterval` and `disabled` values supplied to the nearest `motionManager(updateInterval:disabled:)` modifier with the scene lifecycle and the shared ``MotionManager`` state.
    @Entry var sceneMotionEffectsEnabled = false
}
