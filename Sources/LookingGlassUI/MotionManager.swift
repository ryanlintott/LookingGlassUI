//
//  MotionManager.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2020-09-17.
//

import SwiftUI

/// One scene's device-motion configuration.
///
/// Add ``SwiftUICore/View/motionManager(updateInterval:disabled:)`` near the top of each scene's view hierarchy. The modifier creates one of these for that scene and places it in the environment alongside ``DeviceMotion``.
///
/// The values here are the ones that scene asked for, not an app-wide total. Every scene shares one Core Motion service, which runs at the fastest interval any scene needs, so a scene can receive updates faster than it requested but never slower.
///
/// ```swift
/// @EnvironmentObject var motionManager: MotionManager
/// ```
///
/// This object lives as long as the scene does. When the scene goes away it is deallocated and its claim on the shared service goes with it.
@MainActor
public final class MotionManager: ObservableObject {
    /// The interval between motion samples this scene asked for, in seconds.
    ///
    /// The shared service runs at the fastest interval any scene asked for, so samples can arrive faster than this. ``DeviceMotion/updateInterval`` reports the rate they actually arrive at.
    @Published public private(set) var preferredUpdateInterval: TimeInterval

    /// Whether this scene has disabled motion updates.
    @Published public private(set) var disabled: Bool

    /// The operational state of the scene.
    private(set) var scenePhase: ScenePhase

    /// Creates a scene's manager and adds it to the shared service.
    ///
    /// - Parameters:
    ///   - updateInterval: The requested interval between motion samples, in seconds.
    ///   - disabled: Whether the scene has disabled motion updates.
    ///   - scenePhase: The operational state of the scene.
    init(updateInterval: TimeInterval, disabled: Bool, scenePhase: ScenePhase) {
        self.preferredUpdateInterval = updateInterval
        self.disabled = disabled
        self.scenePhase = scenePhase

        MotionService.shared.add(self)
    }

    deinit {
        /// The service holds its managers weakly, so this reference is already gone by the time the reconcile runs and there's nothing to pass it. Reconciling is all that's left to do.
        Task { @MainActor in
            MotionService.shared.reconcile()
        }
    }

    /// Whether motion updates are enabled for this scene.
    ///
    /// Deliberately independent of the scene lifecycle: a backgrounded scene keeps its effects on screen, where they're still captured in the app switcher snapshot, and only stops receiving new samples.
    public var isDetectingMotion: Bool {
        preferredUpdateInterval > 0 && !disabled
    }

    /// Whether this scene currently needs the shared motion service running.
    ///
    /// The same as ``isDetectingMotion`` but for the scene lifecycle, which is what separates asking for updates from receiving them.
    var needsMotionService: Bool {
        scenePhase != .background && isDetectingMotion
    }

    @available(*, unavailable, renamed: "preferredUpdateInterval", message: "Renamed because a scene can receive samples faster than it asked for. `DeviceMotion.updateInterval` reports the rate they actually arrive at.")
    public var updateInterval: TimeInterval { fatalError() }

    /// Applies a new configuration and reconciles the shared service when something changed.
    ///
    /// - Parameters:
    ///   - updateInterval: The requested interval between motion samples, in seconds.
    ///   - disabled: Whether the scene has disabled motion updates.
    ///   - scenePhase: The operational state of the scene.
    func update(updateInterval: TimeInterval, disabled: Bool, scenePhase: ScenePhase) {
        /// Gated one value at a time as the published ones refresh this scene's views on every assignment, and a scene phase change on its own must not do that.
        var didChange = false

        if preferredUpdateInterval != updateInterval {
            preferredUpdateInterval = updateInterval
            didChange = true
        }

        if disabled != self.disabled {
            self.disabled = disabled
            didChange = true
        }

        if scenePhase != self.scenePhase {
            self.scenePhase = scenePhase
            didChange = true
        }

        guard didChange else { return }

        MotionService.shared.reconcile()
    }

    @available(*, unavailable, message: "Removed to improve performance. Use `DeviceMotion.currentDeviceRotation`, applying animation as per the documentation for that property. Add `@EnvironmentObject var deviceMotion: DeviceMotion` to your view to access the environment object added with `.motionManager()`.")
    public var animatedQuaternion: Quat { fatalError() }

    @available(*, unavailable, message: "Replaced by `DeviceMotion.currentDeviceRotation`. Add `@EnvironmentObject var deviceMotion: DeviceMotion` to your view to access the environment object added with `.motionManager()`.")
    public var quaternion: Quat { fatalError() }

    @available(*, unavailable, message: "The intial device rotation is no longer saved. `DeviceMotion.settledDeviceRotation` is an alternative which tracks a previous device rotation and eases towards the current rotation rather than staying where it was. Add `@EnvironmentObject var deviceMotion: DeviceMotion` to your view to access the environment object added with `.motionManager()`.")
    public var initialDeviceRotation: Quat? { fatalError() }

    @available(*, unavailable, message: "Replaced by `DeviceMotion.deltaRotation`. Add `@EnvironmentObject var deviceMotion: DeviceMotion` to your view to access the environment object added with `.motionManager()`.")
    public var deltaRotation: Quat { fatalError() }

    @available(*, unavailable, message: "Replaced by `DeviceMotion.interfaceOrientation`, which follows the interface rather than the device and so stays correct while the device is lying flat. Add `@EnvironmentObject var deviceMotion: DeviceMotion` to your view to access the environment object added with `.motionManager()`.")
    public var deviceOrientation: UIDeviceOrientation { fatalError() }

    @available(*, unavailable, message: "Replaced by an optional property `DeviceMotion.interfaceOrientation.rotation` as sometimes the interface orientation is unknown. Add `@EnvironmentObject var deviceMotion: DeviceMotion` to your view to access the environment object added with `.motionManager()`.")
    public var interfaceRotation: Quat { fatalError() }

    @available(*, unavailable, message: "Device orientation is updated internally so this call is no longer required.")
    public func changeDeviceOrientation() { fatalError() }

    @available(*, unavailable, message: "Pass the update interval to `.motionManager(updateInterval:disabled:)` instead.")
    public func setUpdateInterval(_ newUpdateInterval: TimeInterval) { fatalError() }

    @available(*, unavailable, message: "Pass the disabled state to `.motionManager(updateInterval:disabled:)` instead.")
    public func setDisabled(_ newDisabled: Bool) { fatalError() }

    @available(*, unavailable, message: "Motion updates start automatically so this call is no longer required. Configure motion updates with `.motionManager(updateInterval:disabled:)`.")
    public func startMotionUpdates(updateInterval: TimeInterval? = nil, disabled: Bool? = nil, setDeviceOrientation: Bool = false) { fatalError() }

    @available(*, unavailable, message: "Motion updates are managed automatically when their configuration changes, device orientation changes, or the app moves between the foreground and background so this call is no longer required.")
    public func restart() { fatalError() }

    @available(*, unavailable, message: "Motion updates stop automatically when no enabled scene needs them or the app moves to the background so this call is no longer required. Configure motion updates with `.motionManager(updateInterval:disabled:)`.")
    public func stopMotionUpdates() { fatalError() }
}
