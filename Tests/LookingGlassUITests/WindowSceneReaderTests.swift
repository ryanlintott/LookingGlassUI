//
//  WindowSceneReaderTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-09-02.
//

@testable import LookingGlassUI
import SwiftUI
import XCTest

@MainActor
final class WindowSceneReaderTests: XCTestCase {
    private func makeManager(
        preferredUpdateInterval: TimeInterval = 0.1,
        disabled: Bool = false,
        scenePhase: ScenePhase = .active
    ) -> MotionManager {
        MotionManager(preferredUpdateInterval: preferredUpdateInterval, disabled: disabled, scenePhase: scenePhase)
    }

    // MARK: - Which screen a scene is on

    /// Effects here are driven by how the device is moved, which says nothing about content on a display the device is only connected to.
    func testASceneOnAnExternalDisplayDetectsNoMotion() {
        let manager = makeManager()
        XCTAssertTrue(manager.isDetectingMotion)

        manager.setWindowSceneState(WindowSceneState(interfaceOrientation: .portrait, isOnDeviceScreen: false))

        XCTAssertFalse(manager.isDetectingMotion, "a scene on an external display must not run effects")
        XCTAssertFalse(manager.needsMotionService, "a scene on an external display must not drive the sensor")

        withExtendedLifetime(manager) {}
    }

    /// Starting from false instead would blink the effects off and on again in every ordinary scene, to spare a flicker in the rare one.
    func testASceneIsAssumedToBeOnTheDeviceUntilItSaysOtherwise() {
        let manager = makeManager()

        XCTAssertTrue(manager.isOnDeviceScreen)
        XCTAssertTrue(manager.isDetectingMotion)

        withExtendedLifetime(manager) {}
    }

    // MARK: - Reporting the orientation onward

    /// A scene stores what it is told whatever else is true of it, so it is right as soon as it is believed again.
    func testASceneStoresItsOwnOrientationEvenWhenItIsNotBelieved() {
        let manager = makeManager(scenePhase: .background)

        manager.setWindowSceneState(WindowSceneState(interfaceOrientation: .landscapeLeft, isOnDeviceScreen: true))

        XCTAssertEqual(manager.interfaceOrientation, .landscapeLeft)

        withExtendedLifetime(manager) {}
    }

    /// A scene that cannot say which way it is facing leaves the last known orientation in place rather than resetting the world to portrait.
    func testAnUnknownOrientationLeavesTheLastKnownOneInPlace() {
        let manager = makeManager()
        manager.setWindowSceneState(WindowSceneState(interfaceOrientation: .landscapeRight, isOnDeviceScreen: true))

        manager.setWindowSceneState(WindowSceneState(interfaceOrientation: nil, isOnDeviceScreen: true))

        XCTAssertEqual(manager.interfaceOrientation, .landscapeRight)

        withExtendedLifetime(manager) {}
    }

}
