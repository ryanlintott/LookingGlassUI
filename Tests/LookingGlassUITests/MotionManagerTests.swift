//
//  MotionManagerTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-25.
//

@testable import LookingGlassUI
import Combine
import XCTest

@MainActor
final class MotionManagerTests: XCTestCase {
    func testMultipleSceneRequestsUseFastestEnabledIntervalUntilLastEnabledSceneDisappears() {
        let motionManager = MotionManager.shared
        let firstScene = UUID()
        let secondScene = UUID()
        let disabledScene = UUID()
        let unregisteredScene = UUID()

        motionManager.setApplicationActive(false)
        defer {
            motionManager.unregisterMotionUpdates(id: firstScene)
            motionManager.unregisterMotionUpdates(id: secondScene)
            motionManager.unregisterMotionUpdates(id: disabledScene)
            motionManager.setApplicationActive(true)
        }

        motionManager.updateMotionUpdates(id: unregisteredScene, updateInterval: 0.01, disabled: false, scenePhase: .active)
        XCTAssertEqual(motionManager.updateInterval, 0, "updating an unregistered scene must not create a new request")
        XCTAssertFalse(motionManager.isDetectingMotion)

        motionManager.registerMotionUpdates(id: firstScene, updateInterval: 0.1, disabled: false, scenePhase: .active)
        XCTAssertEqual(motionManager.updateInterval, 0.1)
        XCTAssertFalse(motionManager.isDetectingMotion, "an application in the background must not report that it is detecting motion")

        motionManager.registerMotionUpdates(id: secondScene, updateInterval: 0.05, disabled: false, scenePhase: .active)
        XCTAssertEqual(motionManager.updateInterval, 0.05, "the fastest enabled scene should control the shared sensor")

        motionManager.registerMotionUpdates(id: disabledScene, updateInterval: 0.01, disabled: true, scenePhase: .active)
        XCTAssertEqual(motionManager.updateInterval, 0.05, "a disabled scene should not affect the shared sensor interval")

        motionManager.unregisterMotionUpdates(id: secondScene)
        XCTAssertEqual(motionManager.updateInterval, 0.1, "closing one scene should leave another scene's request active")
        XCTAssertFalse(motionManager.isDetectingMotion)

        motionManager.unregisterMotionUpdates(id: firstScene)
        XCTAssertEqual(motionManager.updateInterval, 0)
        XCTAssertTrue(motionManager.disabled)
        XCTAssertFalse(motionManager.isDetectingMotion)

        motionManager.unregisterMotionUpdates(id: disabledScene)
        XCTAssertEqual(motionManager.updateInterval, 0)
        XCTAssertFalse(motionManager.disabled)
        XCTAssertFalse(motionManager.isDetectingMotion)
    }

    func testIsDetectingMotionRequiresApplicationOutsideBackground() {
        let motionManager = MotionManager.shared
        let scene = UUID()

        motionManager.setApplicationActive(false)
        defer {
            motionManager.unregisterMotionUpdates(id: scene)
            motionManager.setApplicationActive(true)
        }

        motionManager.registerMotionUpdates(id: scene, updateInterval: 0.1, disabled: false, scenePhase: .active)
        XCTAssertFalse(motionManager.isDetectingMotion)

        motionManager.setApplicationActive(true)
        XCTAssertTrue(motionManager.isDetectingMotion)

        motionManager.setApplicationActive(false)
        XCTAssertFalse(motionManager.isDetectingMotion)
    }

    func testMotionEffectsEnabledUsesPublishedRegistrationState() {
        let motionManager = MotionManager.shared
        let controllingScene = UUID()
        let slowerScene = UUID()
        let unregisteredScene = UUID()

        motionManager.setApplicationActive(false)
        defer {
            motionManager.unregisterMotionUpdates(id: controllingScene)
            motionManager.unregisterMotionUpdates(id: slowerScene)
            motionManager.setApplicationActive(true)
        }

        motionManager.registerMotionUpdates(id: controllingScene, updateInterval: 0.05, disabled: false, scenePhase: .active)
        motionManager.setApplicationActive(true)
        XCTAssertFalse(motionManager.motionEffectsEnabled(id: unregisteredScene))

        var managerChangeCount = 0
        let cancellable = motionManager.objectWillChange.sink {
            managerChangeCount += 1
        }

        motionManager.registerMotionUpdates(id: slowerScene, updateInterval: 0.1, disabled: false, scenePhase: .active)
        XCTAssertEqual(motionManager.updateInterval, 0.05, "a slower registration should not change the effective interval")
        XCTAssertGreaterThan(managerChangeCount, 0, "registering a scene must refresh observing modifiers even when the effective interval is unchanged")
        XCTAssertTrue(motionManager.motionEffectsEnabled(id: slowerScene))

        motionManager.updateMotionUpdates(id: slowerScene, updateInterval: 0.1, disabled: false, scenePhase: .inactive)
        XCTAssertTrue(motionManager.motionEffectsEnabled(id: slowerScene))

        motionManager.updateMotionUpdates(id: slowerScene, updateInterval: 0.1, disabled: true, scenePhase: .active)
        XCTAssertFalse(motionManager.motionEffectsEnabled(id: slowerScene))

        motionManager.updateMotionUpdates(id: slowerScene, updateInterval: 0.1, disabled: false, scenePhase: .background)
        XCTAssertFalse(motionManager.motionEffectsEnabled(id: slowerScene))

        motionManager.unregisterMotionUpdates(id: slowerScene)
        XCTAssertFalse(motionManager.motionEffectsEnabled(id: slowerScene))

        withExtendedLifetime(cancellable) {}
    }

    func testBackgroundSceneRequestsDoNotAffectForegroundConfiguration() {
        let motionManager = MotionManager.shared
        let foregroundScene = UUID()
        let backgroundScene = UUID()

        motionManager.setApplicationActive(false)
        defer {
            motionManager.unregisterMotionUpdates(id: foregroundScene)
            motionManager.unregisterMotionUpdates(id: backgroundScene)
            motionManager.setApplicationActive(true)
        }

        motionManager.registerMotionUpdates(
            id: foregroundScene,
            updateInterval: 0.1,
            disabled: false,
            scenePhase: .active
        )
        motionManager.registerMotionUpdates(
            id: backgroundScene,
            updateInterval: 0.01,
            disabled: false,
            scenePhase: .background
        )
        XCTAssertEqual(motionManager.updateInterval, 0.1, "a background scene must not control the shared sensor interval")

        motionManager.updateMotionUpdates(
            id: backgroundScene,
            updateInterval: 0.01,
            disabled: false,
            scenePhase: .inactive
        )
        XCTAssertEqual(motionManager.updateInterval, 0.01, "an inactive scene remains in the foreground")

        motionManager.updateMotionUpdates(
            id: backgroundScene,
            updateInterval: 0.01,
            disabled: false,
            scenePhase: .background
        )
        motionManager.updateMotionUpdates(
            id: foregroundScene,
            updateInterval: 0.1,
            disabled: false,
            scenePhase: .background
        )
        XCTAssertEqual(motionManager.updateInterval, 0)
        XCTAssertFalse(motionManager.disabled, "no foreground request is distinct from every foreground request being disabled")
        XCTAssertFalse(motionManager.isDetectingMotion)
    }
}
