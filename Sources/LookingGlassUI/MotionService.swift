//
//  MotionService.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-26.
//

import CoreMotion
import SwiftUI

/// The app's single Core Motion service and the device-wide state derived from it.
///
/// Each scene's ``MotionManager`` adds itself here when it's created. The service keeps the sensor matched to the fastest interval any live scene needs and stops it when none do.
@MainActor
final class MotionService: ObservableObject {
    /// The service shared by every scene in the app.
    static let shared = MotionService()

    /// Whether LookingGlassUI views print the reason their bodies are evaluated.
    ///
    /// Each motion update is preceded by a numbered marker so the view updates that follow it can be attributed to that motion update. Useful for checking how many view updates each motion update triggers. Printing is slow enough to distort timings so use this to count updates, not to measure their cost. Has no effect outside debug builds.
    static var isPrintingViewChanges: Bool = false

    /// Counts motion updates while ``isPrintingViewChanges`` is on.
    private static var motionUpdateCount: Int = 0

    /// A scene manager held weakly, so a closed scene's request disappears with the scene.
    private struct WeakManager {
        weak var manager: MotionManager?
    }

    /// The single Core Motion manager that supplies device-motion updates for the app.
    private let cmManager = CMMotionManager()

    /// The scene managers currently alive.
    private var managers: [WeakManager] = []

    /// Identifies one run of the sensor, so a sample from an earlier run can be told apart from a current one.
    ///
    /// Each run measures attitude against its own reference frame, and the default frame's horizontal axis points in an arbitrary direction picked from wherever the device happened to be pointing when that run started. Samples from two runs are not comparable and can disagree by most of a turn.
    ///
    /// Stopping the sensor doesn't drop the samples already queued for the main queue, and during an interface rotation that queue is busy enough for several to be waiting. One arriving after the next run has started would be measured against the frame it came from and, worse, could become the settled rotation that run is then measured against, leaving ``DeviceMotion/deltaRotation`` wrong by the difference between the two frames until the settling eases it out.
    private var motionSession: Int = 0

    /// The current and initial device rotations derived from Core Motion updates.
    let deviceMotion = DeviceMotion.shared

    /// The screen size in the current interface orientation.
    ///
    /// Seeded from `UIScreen.bounds`, which reports the interface orientation the app launched in, and updated whenever the device turns to an orientation the interface follows. It's stored rather than derived from ``DeviceMotion/interfaceOrientation`` because that starts out nil: a device lying flat has no supported orientation to report, so at launch the bounds are the only thing that knows which way the interface is facing.
    @Published private(set) var interfaceSize: CGSize = UIScreen.main.bounds.size

    /// Whether the application is outside the background and may run the sensor.
    private var isApplicationActive: Bool

    /// Tokens that identify the service's notification subscriptions.
    private var notificationObservers: [NSObjectProtocol] = []

    /// Creates the shared service and begins observing orientation and application-lifecycle changes.
    private init() {
        isApplicationActive = UIApplication.shared.applicationState != .background
        startObservingNotifications()
        refreshInterfaceOrientation()
    }

    /// Whether the Core Motion service should be running.
    ///
    /// The application state is used here and nowhere else, so backgrounding stops the service without turning off the effects it feeds.
    var needsMotionService: Bool {
        isApplicationActive && deviceMotion.updateInterval > 0
    }

    /// Adds a scene's manager and reconciles the service.
    ///
    /// - Parameter manager: The manager to add. It is held weakly.
    func add(_ manager: MotionManager) {
        managers.append(WeakManager(manager: manager))
        reconcile()
    }

    /// Matches the sensor to the scenes that are currently alive.
    ///
    /// Managers that have been deallocated are dropped here rather than removing themselves, so a scene torn down without warning leaves nothing behind.
    func reconcile() {
        managers.removeAll { $0.manager == nil }

        let newUpdateInterval = managers
            .compactMap(\.manager)
            .filter(\.needsMotionService)
            .map(\.preferredUpdateInterval)
            .min() ?? 0

        deviceMotion.setUpdateInterval(newUpdateInterval)

        restartMotionUpdatesIfNeeded()
    }

    /// Records whether the application is outside the background and reconciles the service.
    ///
    /// - Parameter isActive: `true` when motion updates may run; `false` while the application is in the background.
    func setApplicationActive(_ isActive: Bool) {
        guard isApplicationActive != isActive else { return }
        isApplicationActive = isActive
        restartMotionUpdatesIfNeeded()
    }
    
    /// Reads the orientation the interface is showing, updates ``interfaceSize`` and re-starts motion updates when it has changed.
    ///
    /// The window scene can become readable after this object is created, so this is called again whenever that could have happened rather than only once. Most of those calls find nothing new, so the sensor is only restarted when the orientation actually changed.
    func refreshInterfaceOrientation() {
        guard let newInterfaceOrientation = UIInterfaceOrientation.current else {
            return
        }
        
        if let newInterfaceSize = newInterfaceOrientation.screenSize,
           interfaceSize != newInterfaceSize {
            interfaceSize = newInterfaceSize
        }
        
        let forceRestart = deviceMotion.setInterfaceOrientation(newInterfaceOrientation)

        restartMotionUpdatesIfNeeded(forceRestart: forceRestart)
    }
    
    private func stopMotionUpdates() {
        motionSession &+= 1
        cmManager.stopDeviceMotionUpdates()
        deviceMotion.resetSettledDeviceRotation()
    }
    
    /// Makes the Core Motion service match the scenes that need it and the application state.
    ///
    /// - Parameter forceRestart: Whether to restart an already-requested service even when its interval is unchanged.
    private func restartMotionUpdatesIfNeeded(forceRestart: Bool = false) {
        guard needsMotionService else {
            if cmManager.isDeviceMotionActive {
                stopMotionUpdates()
            }
            return
        }

        let requiresRestart = forceRestart
            || !cmManager.isDeviceMotionActive
            || cmManager.deviceMotionUpdateInterval != deviceMotion.updateInterval

        guard requiresRestart else { return }

        if cmManager.isDeviceMotionActive {
            stopMotionUpdates()
        }
        /// Start motion updates
        motionSession &+= 1
        let session = motionSession
        deviceMotion.resetSettledDeviceRotation()
        
        cmManager.deviceMotionUpdateInterval = deviceMotion.updateInterval

        cmManager.startDeviceMotionUpdates(to: .main) { motionData, error in
            guard session == self.motionSession else { return }
            if let motionData = motionData {
                #if DEBUG
                if Self.isPrintingViewChanges {
                    Self.motionUpdateCount += 1
                    print("=== motion update \(Self.motionUpdateCount) ===")
                }
                #endif

                self.deviceMotion.setCurrentDeviceRotation(to: Quat(motionData.attitude.quaternion))

            } else if let error = error {
                print(error.localizedDescription)
            } else {
                print("Error - Unknown motion update error")
            }
        }
    }

    /// Subscribes the service to device-orientation and application-lifecycle notifications.
    private func startObservingNotifications() {
        let notificationCenter = NotificationCenter.default

        notificationObservers = [
            /// The device turning is what makes the interface turn, so this is the signal that the scene may now report something new.
            notificationCenter.addObserver(
                forName: UIDevice.orientationDidChangeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshInterfaceOrientation()
                }
            },
            /// A scene has no readable orientation until it activates, which can happen after this service is created.
            notificationCenter.addObserver(
                forName: UIScene.didActivateNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.refreshInterfaceOrientation()
                }
            },
            notificationCenter.addObserver(
                forName: UIApplication.willEnterForegroundNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.refreshInterfaceOrientation()
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
}
