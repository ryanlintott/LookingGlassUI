//
//  MotionManager.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2020-09-17.
//

import SwiftUI

/// One scene's device-motion configuration.
///
/// Add ``SwiftUICore/View/motionManager(preferredUpdateInterval:disabled:)`` near the top of each scene's view hierarchy. The modifier creates one of these for that scene and places it in the environment alongside ``DeviceMotion``.
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

    /// The frame in which any device rotation effects are centred, in SwiftUI's global coordinate space.
    ///
    /// This is the frame of the view ``SwiftUICore/View/motionManager(preferredUpdateInterval:disabled:)`` was applied to, which is a scene's whole window when the modifier is added where it is meant to be. Every device rotation effect in the scene turns about the centre of this frame rather than about its own centre, which is what makes them read as one window/reflection rather than as one per view.
    ///
    /// Each scene measures its own, so two windows side by side each turn about their own centre.
    ///
    /// Nil until this scene's views have been laid out.
    @Published private(set) var containerFrame: CGRect? = nil

    /// The operational state of the scene.
    private(set) var scenePhase: ScenePhase

    /// The orientation this scene's interface is showing.
    ///
    /// This is what the interface is facing, unlike `UIDevice.current.orientation`, which reports where the device is physically pointing. That is unknown at launch and face up or face down whenever the device is lying flat, none of which say which way the interface is facing.
    ///
    /// Nil until this scene's views reach a window and it reports one.
    @Published public private(set) var interfaceOrientation: UIInterfaceOrientation? = nil

    /// Whether this scene is showing on the device's own screen.
    ///
    /// Effects here are driven by how the device is being moved, which says nothing about content on a display the device is merely connected to, so a scene on an external display never detects motion. See ``isDetectingMotion``.
    ///
    /// Assumed true until this scene's views reach a window and report otherwise. Starting from false instead would blink the effects off and on again in every ordinary scene, to spare a flicker in the rare one.
    @Published private(set) var isOnDeviceScreen: Bool = true

    /// Creates a scene's manager and adds it to the shared service.
    ///
    /// - Parameters:
    ///   - preferredUpdateInterval: The requested interval between motion samples, in seconds.
    ///   - disabled: Whether the scene has disabled motion updates.
    ///   - scenePhase: The operational state of the scene.
    init(preferredUpdateInterval: TimeInterval, disabled: Bool, scenePhase: ScenePhase) {
        self.preferredUpdateInterval = preferredUpdateInterval
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
    /// Deliberately independent of the scene lifecycle: a backgrounded scene keeps its effects on screen, where they're still captured in the app switcher snapshot, and only stops receiving new samples. A scene on an external display is a different matter and is excluded outright, as no movement of the device changes how content there should look.
    public var isDetectingMotion: Bool {
        isOnDeviceScreen && preferredUpdateInterval > 0 && !disabled
    }

    /// Whether this scene currently needs the shared motion service running.
    ///
    /// The same as ``isDetectingMotion`` but for the scene lifecycle, which is what separates asking for updates from receiving them.
    var needsMotionService: Bool {
        scenePhase != .background && isDetectingMotion
    }

    @available(*, unavailable, renamed: "preferredUpdateInterval", message: "Renamed because a scene can receive samples faster than it asked for. `DeviceMotion.updateInterval` reports the rate they actually arrive at.")
    public var updateInterval: TimeInterval { fatalError() }

    /// Stores what this scene reports about itself and passes the orientation on to the shared service.
    ///
    /// Reported by ``SwiftUICore/View/motionManager(preferredUpdateInterval:disabled:)`` on every layout pass and on every motion update, so most calls find nothing new.
    ///
    /// - Parameter windowSceneState: What the scene the modified views are in says about itself.
    func setWindowSceneState(_ windowSceneState: WindowSceneState) {
        /// Gated one value at a time as the published ones refresh this scene's views on every assignment.
        if let interfaceOrientation = windowSceneState.interfaceOrientation,
           self.interfaceOrientation != interfaceOrientation {
            self.interfaceOrientation = interfaceOrientation
        }

        if isOnDeviceScreen != windowSceneState.isOnDeviceScreen {
            isOnDeviceScreen = windowSceneState.isOnDeviceScreen
            /// ``isDetectingMotion`` has changed, so whether this scene needs the sensor has changed with it.
            MotionService.shared.reconcile()
        }

        reportInterfaceOrientation()
    }

    /// Passes this scene's interface orientation to the shared service, when this scene is one that should be believed.
    ///
    /// Every scene reports to one shared ``DeviceMotion`` and the last report wins. Scenes sharing a screen are all facing the same way, so they agree. The two that would not are excluded here: a scene on an external display faces a direction that says nothing about how the device is held, and a scene outside the foreground can report an orientation it has not caught up on.
    private func reportInterfaceOrientation() {
        guard isOnDeviceScreen,
              scenePhase != .background,
              let interfaceOrientation
        else { return }

        MotionService.shared.setInterfaceOrientation(interfaceOrientation)
    }

    /// Stores the frame device rotation effects are centred in.
    ///
    /// Measured by ``SwiftUICore/View/motionManager(preferredUpdateInterval:disabled:)``, which reports on every layout pass, so an unchanged frame is dropped here rather than refreshing this scene's views for a measurement that said nothing new.
    ///
    /// - Parameter containerFrame: The frame of the view the modifier was applied to, in the global coordinate space.
    func setContainerFrame(_ containerFrame: CGRect) {
        guard self.containerFrame != containerFrame else { return }

        self.containerFrame = containerFrame
    }

    /// Applies a new configuration and reconciles the shared service when something changed.
    ///
    /// - Parameters:
    ///   - preferredUpdateInterval: The requested interval between motion samples, in seconds.
    ///   - disabled: Whether the scene has disabled motion updates.
    ///   - scenePhase: The operational state of the scene.
    func update(preferredUpdateInterval: TimeInterval, disabled: Bool, scenePhase: ScenePhase) {
        /// Gated one value at a time as the published ones refresh this scene's views on every assignment, and a scene phase change on its own must not do that.
        var didChange = false

        if self.preferredUpdateInterval != preferredUpdateInterval {
            self.preferredUpdateInterval = preferredUpdateInterval
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

        /// A scene coming back to the foreground stopped being one whose orientation is believed while it was away, so what it knows is passed on again.
        reportInterfaceOrientation()

        MotionService.shared.reconcile()
    }

    @available(*, unavailable, message: "Removed to improve performance. Use `DeviceMotion.currentDeviceRotation`, applying animation as per the documentation for that property. Add `@EnvironmentObject var deviceMotion: DeviceMotion` to your view to access the environment object added with `.motionManager()`.")
    public var animatedQuaternion: Quat { fatalError() }

    @available(*, unavailable, message: "Replaced by `DeviceMotion.currentDeviceRotation`. Add `@EnvironmentObject var deviceMotion: DeviceMotion` to your view to access the environment object added with `.motionManager()`.")
    public var quaternion: Quat { fatalError() }

    @available(*, unavailable, message: "The initial device rotation is no longer saved. `DeviceMotion.settledDeviceRotation` is an alternative which tracks a previous device rotation and eases towards the current rotation rather than staying where it was. Add `@EnvironmentObject var deviceMotion: DeviceMotion` to your view to access the environment object added with `.motionManager()`.")
    public var initialDeviceRotation: Quat? { fatalError() }

    @available(*, unavailable, message: "Replaced by `DeviceMotion.deltaRotation`. Add `@EnvironmentObject var deviceMotion: DeviceMotion` to your view to access the environment object added with `.motionManager()`.")
    public var deltaRotation: Quat { fatalError() }

    @available(*, unavailable, message: "Replaced by `DeviceMotion.interfaceRotation`. Add `@EnvironmentObject var deviceMotion: DeviceMotion` to your view to access the environment object added with `.motionManager()`. `interfaceOrientation` on this object reports which way this scene is facing.")
    public var interfaceRotation: Quat { fatalError() }

    @available(*, unavailable, renamed: "interfaceOrientation", message: "Replaced by `interfaceOrientation`, which follows the interface rather than the device and so stays correct while the device is lying flat.")
    public var deviceOrientation: UIDeviceOrientation { fatalError() }

    @available(*, unavailable, message: "Device orientation is updated internally so this call is no longer required.")
    public func changeDeviceOrientation() { fatalError() }

    @available(*, unavailable, message: "Pass the update interval to `.motionManager(preferredUpdateInterval:disabled:)` instead.")
    public func setUpdateInterval(_ newUpdateInterval: TimeInterval) { fatalError() }

    @available(*, unavailable, message: "Pass the disabled state to `.motionManager(preferredUpdateInterval:disabled:)` instead.")
    public func setDisabled(_ newDisabled: Bool) { fatalError() }

    @available(*, unavailable, message: "Motion updates start automatically so this call is no longer required. Configure motion updates with `.motionManager(preferredUpdateInterval:disabled:)`.")
    public func startMotionUpdates(updateInterval: TimeInterval? = nil, disabled: Bool? = nil, setDeviceOrientation: Bool = false) { fatalError() }

    @available(*, unavailable, message: "Motion updates are managed automatically when their configuration changes, device orientation changes, or the app moves between the foreground and background so this call is no longer required.")
    public func restart() { fatalError() }

    @available(*, unavailable, message: "Motion updates stop automatically when no enabled scene needs them or the app moves to the background so this call is no longer required. Configure motion updates with `.motionManager(preferredUpdateInterval:disabled:)`.")
    public func stopMotionUpdates() { fatalError() }
}
