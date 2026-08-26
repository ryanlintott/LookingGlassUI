//
//  MotionManager.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2020-09-17.
//

import CoreMotion
import SwiftUI

/// Coordinates the app's device-motion updates and exposes their effective configuration.
///
/// Add ``SwiftUICore/View/motionManager(updateInterval:disabled:)`` near the top of each scene's view hierarchy. The modifier registers that scene's configuration and places this manager and ``DeviceRotation`` in the environment. All scenes use the same manager and Core Motion service.
@MainActor
public class MotionManager: ObservableObject {
    
    /// A scene's requested motion-update configuration.
    private struct MotionUpdateRequest {
        /// The requested interval between motion samples, in seconds.
        var updateInterval: TimeInterval

        /// Whether the scene has disabled motion updates.
        var disabled: Bool

        /// The operational state of the scene that owns the request.
        var scenePhase: ScenePhase

        /// Whether the request currently participates in the shared motion service.
        var isDetectingMotion: Bool {
            scenePhase != .background && updateInterval > 0 && !disabled
        }
    }
    
    /// The shared manager used by every scene in the app.
    static let shared = MotionManager()
    
    /// Whether LookingGlassUI views print the reason their bodies are evaluated.
    ///
    /// Each motion update is preceded by a numbered marker so the view updates that follow it can be attributed to that motion update. Useful for checking how many view updates each motion update triggers. Printing is slow enough to distort timings so use this to count updates, not to measure their cost. Has no effect outside debug builds.
    static var isPrintingViewChanges: Bool = false
    
    /// Counts motion updates while ``isPrintingViewChanges`` is on.
    private static var motionUpdateCount: Int = 0

    /// The single Core Motion manager that supplies device-motion updates for the app.
    private let cmManager = CMMotionManager()
    
    /// The current and initial device rotations derived from Core Motion updates.
    public let deviceRotation = DeviceRotation()

    /// Motion-update requests keyed by the identifier of their registered scene modifier.
    ///
    /// Publishing changes lets each scene modifier refresh its local environment value even when the app-wide effective configuration is unchanged.
    @Published private var motionUpdateRequests: [UUID: MotionUpdateRequest] = [:]

    /// Whether the application is outside the background and may run the motion service.
    @Published private var isApplicationActive = true

    /// The effective interval between motion samples, in seconds.
    ///
    /// With registered scenes, this is the shortest positive interval requested by an enabled foreground scene, or zero when there is no such request.
    @Published public private(set) var updateInterval: TimeInterval = 0

    /// Whether the effective configuration disables motion updates.
    ///
    /// With registered scenes, this is true only when every foreground request is disabled. It is false when no scene is in the foreground.
    @Published public private(set) var disabled: Bool = false
    
    /// The most recent supported physical orientation reported by the device.
    ///
    /// Unknown, face-up, face-down, and orientations excluded by the app's supported interface orientations do not replace the current value.
    @Published public private(set) var deviceOrientation: UIDeviceOrientation = .unknown
    
    /// Tokens that identify the manager's notification subscriptions.
    private var notificationObservers: [NSObjectProtocol] = []
    
    /// Creates the shared manager and begins observing orientation and application-lifecycle changes.
    private init() {
        isApplicationActive = UIApplication.shared.applicationState != .background
        startObservingNotifications()
        _ = setDeviceOrientationIfNeeded()
    }
    
    /// A linear animation whose duration matches ``updateInterval``.
    ///
    /// Apply this animation to values derived from ``deviceRotation`` to smooth the transition between motion samples.
    public var animation: Animation {
        .linear(duration: updateInterval)
    }
    
    /// The quaternion that compensates for the current interface orientation.
    ///
    /// Use this rotation when converting device-reference motion into screen-relative motion.
    public var interfaceRotation: Quat {
        switch deviceOrientation {
        // top of device to the left
        case .landscapeLeft:
            return Quat(angle: .radians(-.pi / 2), axis: .zAxis)
        // top of device to the right
        case .landscapeRight:
            return Quat(angle: .radians(.pi / 2), axis: .zAxis)
        case .portraitUpsideDown:
            return Quat(angle: .radians(.pi), axis: .zAxis)
        default:
            return .identity
        }
    }
    
    /// Whether the application and effective configuration currently request motion updates.
    ///
    /// This is false while the application is in the background, when there is no enabled foreground request with a positive interval, or when every foreground request is disabled. It does not report Core Motion hardware availability.
    public var isDetectingMotion: Bool {
        isApplicationActive && updateInterval > 0 && !disabled
    }

    /// Whether motion effects can currently run for a registered scene modifier.
    ///
    /// - Parameter id: The scene modifier's registration identifier.
    /// - Returns: `true` when both the scene request and shared motion service are enabled; otherwise, `false`.
    func motionEffectsEnabled(id: UUID) -> Bool {
        guard isDetectingMotion, let request = motionUpdateRequests[id] else { return false }
        return request.isDetectingMotion
    }
    
    /// Adds or replaces a scene's motion-update request and applies the effective configuration.
    ///
    /// - Parameters:
    ///   - id: The scene modifier's registration identifier.
    ///   - updateInterval: The requested interval between motion samples, in seconds.
    ///   - disabled: Whether the scene has disabled motion updates.
    ///   - scenePhase: The operational state of the scene that owns the request.
    func registerMotionUpdates(id: UUID, updateInterval: TimeInterval, disabled: Bool, scenePhase: ScenePhase) {
        motionUpdateRequests[id] = MotionUpdateRequest(
            updateInterval: updateInterval,
            disabled: disabled,
            scenePhase: scenePhase
        )
        applyMotionUpdateRequests()
    }

    /// Updates an existing scene's motion-update request and applies the effective configuration.
    ///
    /// If `id` is not registered, this method has no effect.
    ///
    /// - Parameters:
    ///   - id: The scene modifier's registration identifier.
    ///   - updateInterval: The requested interval between motion samples, in seconds.
    ///   - disabled: Whether the scene has disabled motion updates.
    ///   - scenePhase: The operational state of the scene that owns the request.
    func updateMotionUpdates(id: UUID, updateInterval: TimeInterval, disabled: Bool, scenePhase: ScenePhase) {
        guard motionUpdateRequests[id] != nil else { return }

        motionUpdateRequests[id] = MotionUpdateRequest(
            updateInterval: updateInterval,
            disabled: disabled,
            scenePhase: scenePhase
        )
        applyMotionUpdateRequests()
    }

    /// Removes a scene's motion-update request and applies the effective configuration.
    ///
    /// - Parameter id: The scene modifier's registration identifier.
    func unregisterMotionUpdates(id: UUID) {
        motionUpdateRequests[id] = nil
        applyMotionUpdateRequests()
    }

    /// Records whether the application is outside the background and reconciles the shared motion service.
    ///
    /// - Parameter isActive: `true` when motion updates may run; `false` while the application is in the background.
    func setApplicationActive(_ isActive: Bool) {
        guard isApplicationActive != isActive else { return }
        isApplicationActive = isActive
        restartMotionUpdatesIfNeeded()
    }

    /// Publishes the aggregate scene configuration and reconciles the shared motion service.
    private func applyMotionUpdateRequests() {
        let foregroundRequests = motionUpdateRequests.values.filter { $0.scenePhase != .background }

        let minimumActiveUpdateInterval = foregroundRequests
            .filter(\.isDetectingMotion)
            .map(\.updateInterval)
            .min() ?? 0
        
        let allRequestsDisabled = !foregroundRequests.isEmpty && foregroundRequests.allSatisfy(\.disabled)

        if updateInterval != minimumActiveUpdateInterval {
            updateInterval = minimumActiveUpdateInterval
        }

        if disabled != allRequestsDisabled {
            disabled = allRequestsDisabled
        }

        restartMotionUpdatesIfNeeded()
    }

    /// Applies the current device orientation when it is supported and different from ``deviceOrientation``.
    ///
    /// - Returns: `true` when a different orientation was applied; otherwise, `false`.
    private func setDeviceOrientationIfNeeded() -> Bool {
        let newOrientation = UIDevice.current.orientation

        guard deviceOrientation != newOrientation,
              InfoDictionary.supportedOrientations.contains(newOrientation) else {
            return false
        }

        deviceRotation.resetInitialRotation()
        deviceOrientation = newOrientation
        return true
    }

    /// Makes the Core Motion service match the effective configuration and application state.
    ///
    /// - Parameter forceRestart: Whether to restart an already-requested service even when its effective interval is unchanged.
    private func restartMotionUpdatesIfNeeded(forceRestart: Bool = false) {
        guard isDetectingMotion else {
            if cmManager.isDeviceMotionActive {
                cmManager.stopDeviceMotionUpdates()
            }
            return
        }

        let requiresRestart = forceRestart
            || !cmManager.isDeviceMotionActive
            || cmManager.deviceMotionUpdateInterval != updateInterval

        guard requiresRestart else { return }

        if cmManager.isDeviceMotionActive {
            cmManager.stopDeviceMotionUpdates()
        }
        cmManager.deviceMotionUpdateInterval = updateInterval

        cmManager.startDeviceMotionUpdates(to: .main) { motionData, error in
            if let motionData = motionData {
                #if DEBUG
                if Self.isPrintingViewChanges {
                    Self.motionUpdateCount += 1
                    print("=== motion update \(Self.motionUpdateCount) ===")
                }
                #endif
                
                self.deviceRotation.update(quaternion: Quat(motionData.attitude.quaternion))
                
            } else if let error = error {
                print(error.localizedDescription)
            } else {
                print("Error - Unknown motion update error")
            }
        }
    }
    
    /// Subscribes the manager to device-orientation and application-lifecycle notifications.
    private func startObservingNotifications() {
        let notificationCenter = NotificationCenter.default

        notificationObservers = [
            notificationCenter.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self, self.setDeviceOrientationIfNeeded() else { return }
                    self.restartMotionUpdatesIfNeeded(forceRestart: true)
                }
            },
            notificationCenter.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    _ = self.setDeviceOrientationIfNeeded()
                    self.setApplicationActive(true)
                }
            },
            notificationCenter.addObserver(
                forName: UIApplication.didEnterBackgroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.setApplicationActive(false)
                }
            },
        ]
    }
    
    @available(*, unavailable, message: "Removed to improve performance. Use `motionManager.deviceRotation.quaternion` instead and apply animation as per the documentation for that property.")
    public var animatedQuaternion: Quat { fatalError() }
    
    @available(*, unavailable, message: "Moved to DeviceRotation. Read it from `motionManager.deviceRotation` or add `@EnvironmentObject var deviceRotation: DeviceRotation` to your view.")
    public var quaternion: Quat { fatalError() }
    
    @available(*, unavailable, message: "Moved to DeviceRotation. Read it from `motionManager.deviceRotation` or add `@EnvironmentObject var deviceRotation: DeviceRotation` to your view.")
    public var initialDeviceRotation: Quat? { fatalError() }
    
    @available(*, unavailable, message: "Moved to DeviceRotation. Read it from `motionManager.deviceRotation` or add `@EnvironmentObject var deviceRotation: DeviceRotation` to your view.")
    public var deltaRotation: Quat { fatalError() }
    
    @available(*, unavailable, message: "Device orientation is updated internally so this call is no longer required.")
    public func changeDeviceOrientation() { fatalError() }
    
    @available(*, unavailable, message: "Pass the update interval to `.motionManager(updateInterval:disabled:)` instead.")
    public func setUpdateInterval(_ newUpdateInterval: TimeInterval) { fatalError() }
    
    @available(*, unavailable, message: "Pass the disabled state to `.motionManager(updateInterval:disabled:)` instead.")
    public func setDisabled(_ newDisabled: Bool) { fatalError() }
    
    @available(*, unavailable, message: "Configure motion updates with `.motionManager(updateInterval:disabled:)`; they start automatically.")
    public func startMotionUpdates(updateInterval: TimeInterval? = nil, disabled: Bool? = nil, setDeviceOrientation: Bool = false) { fatalError() }
    
    @available(*, unavailable, message: "Motion updates are managed automatically when their configuration changes, device orientation changes, or the app moves between the foreground and background.")
    public func restart() { fatalError() }
    
    @available(*, unavailable, message: "Configure motion updates with `.motionManager(updateInterval:disabled:)`; they stop automatically when no enabled scene needs them or the app enters the background.")
    public func stopMotionUpdates() { fatalError() }
}

struct MotionManager_Previews: PreviewProvider {
    static var previews: some View {
        Color.blue
            .motionManager(updateInterval: 0)
    }
}
