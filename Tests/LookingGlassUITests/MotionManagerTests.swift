//
//  MotionManagerTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-25.
//

@testable import LookingGlassUI
import Combine
import SwiftUI
import XCTest

@MainActor
final class MotionManagerTests: XCTestCase {
    private func makeManager(
        updateInterval: TimeInterval = 0.1,
        disabled: Bool = false,
        scenePhase: ScenePhase = .active
    ) -> MotionManager {
        MotionManager(updateInterval: updateInterval, disabled: disabled, scenePhase: scenePhase)
    }

    override func setUp() async throws {
        MotionService.shared.setApplicationActive(true)
    }

    func testMotionUpdatesFollowTheRequestedConfiguration() {
        let manager = makeManager(updateInterval: 0.1, disabled: false)
        XCTAssertTrue(manager.motionUpdatesEnabled)
        XCTAssertTrue(manager.needsMotionService)

        manager.update(updateInterval: 0, disabled: false, scenePhase: .active)
        XCTAssertFalse(manager.motionUpdatesEnabled, "a zero interval is a request for no updates")

        manager.update(updateInterval: 0.1, disabled: true, scenePhase: .active)
        XCTAssertFalse(manager.motionUpdatesEnabled)
    }

    /// Backgrounding stops motion updates but must leave the effects they feed on screen, or the app switcher snapshot is taken without them.
    func testMotionUpdatesStayEnabledWhileBackgrounded() {
        let manager = makeManager()

        manager.update(updateInterval: 0.1, disabled: false, scenePhase: .background)
        XCTAssertTrue(manager.motionUpdatesEnabled, "the scene entering the background must not turn its effects off")
        XCTAssertFalse(manager.needsMotionService, "the scene entering the background must stop its motion updates")

        manager.update(updateInterval: 0.1, disabled: false, scenePhase: .inactive)
        XCTAssertTrue(manager.needsMotionService, "an inactive scene remains in the foreground")
    }

    func testFastestSceneDrivesTheSharedServiceInterval() {
        let service = MotionService.shared

        let slow = makeManager(updateInterval: 0.1)
        XCTAssertEqual(service.deviceMotion.activeUpdateInterval, 0.1)

        let fast = makeManager(updateInterval: 0.05)
        XCTAssertEqual(service.deviceMotion.activeUpdateInterval, 0.05, "the fastest enabled scene should control the shared service")

        let disabled = makeManager(updateInterval: 0.01, disabled: true)
        XCTAssertEqual(service.deviceMotion.activeUpdateInterval, 0.05, "a disabled scene should not affect the shared interval")

        let backgrounded = makeManager(updateInterval: 0.01, scenePhase: .background)
        XCTAssertEqual(service.deviceMotion.activeUpdateInterval, 0.05, "a backgrounded scene should not affect the shared interval")

        withExtendedLifetime([slow, fast, disabled, backgrounded]) {}
    }

    /// The service holds its managers weakly, so a scene torn down without warning cannot leave a request behind that keeps the sensor running.
    func testDeallocatedSceneStopsDrivingTheSharedService() {
        let service = MotionService.shared

        let kept = makeManager(updateInterval: 0.1)

        do {
            let temporary = makeManager(updateInterval: 0.01)
            XCTAssertEqual(service.deviceMotion.activeUpdateInterval, 0.01)
            withExtendedLifetime(temporary) {}
        }

        service.reconcile()
        XCTAssertEqual(service.deviceMotion.activeUpdateInterval, 0.1, "a deallocated scene must stop driving the shared service")

        withExtendedLifetime(kept) {}
    }

    func testSharedServiceStopsWhenNoSceneNeedsIt() {
        let service = MotionService.shared

        do {
            let manager = makeManager(updateInterval: 0.1)
            XCTAssertTrue(service.needsMotionService)
            withExtendedLifetime(manager) {}
        }

        service.reconcile()
        XCTAssertEqual(service.deviceMotion.activeUpdateInterval, 0)
        XCTAssertFalse(service.needsMotionService)
    }

    func testApplicationBackgroundStopsTheServiceWithoutDisablingUpdates() {
        let service = MotionService.shared
        let manager = makeManager(updateInterval: 0.1)

        XCTAssertTrue(service.needsMotionService)

        service.setApplicationActive(false)
        XCTAssertFalse(service.needsMotionService, "the application entering the background must stop the service")
        XCTAssertTrue(manager.motionUpdatesEnabled, "the application entering the background must not turn effects off")

        service.setApplicationActive(true)
        XCTAssertTrue(service.needsMotionService)

        withExtendedLifetime(manager) {}
    }

    /// The animation must match the rate samples actually arrive at, which is the shared interval rather than the one any single scene asked for.
    func testDeviceRotationAnimationMatchesTheSharedInterval() {
        let service = MotionService.shared

        let slow = makeManager(updateInterval: 0.5)
        XCTAssertEqual(service.deviceMotion.activeUpdateInterval, 0.5)

        let fast = makeManager(updateInterval: 0.05)
        XCTAssertEqual(service.deviceMotion.activeUpdateInterval, 0.05, "the slower scene receives samples at the faster scene's rate")

        withExtendedLifetime([slow, fast]) {}
    }

    func testConfigurationChangesPublish() {
        let manager = makeManager(updateInterval: 0.1)

        var changeCount = 0
        let cancellable = manager.objectWillChange.sink { changeCount += 1 }

        manager.update(updateInterval: 0.2, disabled: false, scenePhase: .active)
        XCTAssertGreaterThan(changeCount, 0, "a configuration change must refresh the scene's views")

        let countAfterChange = changeCount
        manager.update(updateInterval: 0.2, disabled: false, scenePhase: .active)
        XCTAssertEqual(changeCount, countAfterChange, "an unchanged configuration must not refresh anything")

        withExtendedLifetime(cancellable) {}
    }
}
