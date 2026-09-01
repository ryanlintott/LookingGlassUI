//
//  DeviceMotionTests.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-08-24.
//

@testable import LookingGlassUI
import SwiftUI
import XCTest

@MainActor
final class DeviceMotionTests: XCTestCase {
    /// `DeviceMotion` has a private initializer, so every test shares the one instance.
    private var deviceMotion: DeviceMotion { .shared }

    private static let interval: TimeInterval = 1 / 60

    /// The duration every test below runs at, set in `setUp` rather than relied on as the default, so the settling tests measure a window they chose instead of one that could change underneath them.
    private static let settlingDuration: TimeInterval = 2

    /// Everything read here depends on the interface orientation, the settled rotation, the update interval, and the settling duration, all of which survive between tests on the shared instance. Without this, a test passes or fails depending on which test ran before it.
    override func setUp() async throws {
        /// A zero interval holds the settled rotation still, so every test below measures from a fixed one unless it asks for a live interval. The settling itself is covered separately.
        deviceMotion.setUpdateInterval(0)
        deviceMotion.setSettlingDuration(Self.settlingDuration)
        /// Set away from portrait first, so the change is real and the settled rotation is cleared even when the previous test left it in portrait.
        _ = deviceMotion.setInterfaceOrientation(.landscapeLeft)
        _ = deviceMotion.setInterfaceOrientation(.portrait)
        deviceMotion.setCurrentDeviceRotation(to: .identity)
        deviceMotion.resetSettledDeviceRotation()
    }

    /// Settles the device at a resting attitude, then moves it to a new one, in the given interface orientation.
    ///
    /// The first sample after a reset becomes the settled rotation, so two samples are the minimum needed for any delta to exist.
    private func settle(in orientation: UIInterfaceOrientation, at resting: Quat, thenMoveTo moved: Quat) {
        _ = deviceMotion.setInterfaceOrientation(orientation)
        deviceMotion.resetSettledDeviceRotation()
        deviceMotion.setCurrentDeviceRotation(to: resting)
        deviceMotion.setCurrentDeviceRotation(to: moved)
    }

    // MARK: - Settled rotation

    /// The first sample after a reset defines the settled rotation, and later samples must not carry it along with them or the delta would always be nothing. While the service is stopped it doesn't move at all; the easing it does while running is covered under settling below.
    func testTheFirstSampleAfterAResetBecomesTheSettledRotation() {
        let first = Attitude.pointing(bearing: .degrees(0))
        let second = Attitude.pointing(bearing: .degrees(180))

        deviceMotion.setCurrentDeviceRotation(to: first)
        XCTAssertEqual(deviceMotion.settledDeviceRotation, first)

        deviceMotion.setCurrentDeviceRotation(to: second)
        XCTAssertEqual(deviceMotion.settledDeviceRotation, first, "the settled rotation must not follow later samples")
    }

    /// The sample that sets the settled rotation is also measured against it, so it has to come out as no rotation at all. Any other value is a visible jump on the first frame after motion updates start or the interface turns.
    func testDeltaRotationIsIdentityOnTheSampleThatSetsTheSettledRotation() {
        for orientation in UIInterfaceOrientation.allShowable {
            _ = deviceMotion.setInterfaceOrientation(orientation)
            deviceMotion.resetSettledDeviceRotation()
            deviceMotion.setCurrentDeviceRotation(to: Attitude.pointing(bearing: .degrees(70)))

            assertSameRotation(deviceMotion.deltaRotation, .identity, "content jumped on the first sample in \(orientation.testName)")
        }
    }

    /// The settled rotation is cleared on an orientation change so the delta measures from where the device was when the interface settled, rather than carrying a ninety degree step across the rotation.
    func testChangingTheInterfaceOrientationClearsTheSettledRotation() {
        _ = deviceMotion.setInterfaceOrientation(.portrait)
        deviceMotion.setCurrentDeviceRotation(to: Attitude.pointing(bearing: .degrees(0)))
        XCTAssertNotNil(deviceMotion.settledDeviceRotation)

        _ = deviceMotion.setInterfaceOrientation(.landscapeLeft)
        XCTAssertNil(deviceMotion.settledDeviceRotation, "an orientation change must clear the settled rotation")

        deviceMotion.setCurrentDeviceRotation(to: Attitude.pointing(bearing: .degrees(0)))
        _ = deviceMotion.setInterfaceOrientation(.landscapeLeft)
        XCTAssertNotNil(deviceMotion.settledDeviceRotation, "an unchanged orientation must not clear the settled rotation")
    }

    /// The returned flag is what tells `MotionService` to restart the sensor, so reporting a change that did not happen restarts it on every notification that reads the orientation.
    func testSettingTheInterfaceOrientationReportsOnlyRealChanges() {
        _ = deviceMotion.setInterfaceOrientation(.portrait)

        XCTAssertFalse(deviceMotion.setInterfaceOrientation(.portrait), "an unchanged orientation must not report a change")
        XCTAssertTrue(deviceMotion.setInterfaceOrientation(.landscapeLeft), "a new orientation must report a change")
    }

    // MARK: - Delta rotation

    /// The same physical movement of the screen must produce the same rotation however the interface is turned. Measuring it about the device's axes instead put it ninety degrees out in landscape and a hundred and eighty in upside down portrait.
    func testDeltaRotationReproducesAScreenTiltInEveryInterfaceOrientation() {
        let resting = Quat(angle: .degrees(35), axis: .zAxis)
        let tilt = Quat(angle: .degrees(20), axis: .xAxis)

        for orientation in UIInterfaceOrientation.allShowable {
            _ = deviceMotion.setInterfaceOrientation(orientation)
            /// Conjugating by the interface rotation makes `tilt` mean the same physical movement of the screen in every orientation, which is the thing the delta has to recover.
            let interfaceRotation = deviceMotion.interfaceRotation
            settle(in: orientation, at: resting, thenMoveTo: resting * interfaceRotation * tilt * interfaceRotation.inverse)

            assertSameRotation(deviceMotion.deltaRotation, tilt, "the delta was measured about the wrong axes in \(orientation.testName)")
        }
    }

    /// The delta is already in the screen reference frame and must not be converted again. Tilting the top of the screen away from the viewer reads as a positive pitch, and tipping its side reads as a yaw of the opposite sign.
    ///
    /// A stray conversion here reverses both, and every effect measuring from the delta moves the wrong way.
    func testDeltaRotationIsReturnedInTheScreenReferenceFrame() {
        settle(in: .portrait, at: .identity, thenMoveTo: Quat(angle: .degrees(20), axis: .xAxis))
        XCTAssertEqual(deviceMotion.deltaRotation.pitch.degrees, 20, accuracy: 1e-9)

        settle(in: .portrait, at: .identity, thenMoveTo: Quat(angle: .degrees(20), axis: .yAxis))
        XCTAssertEqual(deviceMotion.deltaRotation.yaw.degrees, -20, accuracy: 1e-9)
    }

    /// A tilt about one screen axis must not leak into the other, in any interface orientation. When it did, the parallax effect moved along the wrong axis in landscape.
    func testATiltAboutOneScreenAxisDoesNotLeakIntoTheOther() {
        let tilt = Quat(angle: .degrees(20), axis: .xAxis)

        for orientation in UIInterfaceOrientation.allShowable {
            _ = deviceMotion.setInterfaceOrientation(orientation)
            let interfaceRotation = deviceMotion.interfaceRotation
            settle(in: orientation, at: .identity, thenMoveTo: interfaceRotation * tilt * interfaceRotation.inverse)

            XCTAssertEqual(deviceMotion.deltaRotation.pitch.degrees, 20, accuracy: 1e-9, "pitch was lost in \(orientation.testName)")
            XCTAssertEqual(deviceMotion.deltaRotation.yaw.degrees, 0, accuracy: 1e-9, "the tilt leaked into yaw in \(orientation.testName)")
        }
    }

    // MARK: - Settling

    /// Holds an attitude still for a stretch of time, as a device being kept in one position would. Samples arrive at whatever interval the service is currently running at, so this is a duration rather than a count.
    private func hold(_ attitude: Quat, seconds: TimeInterval) {
        for _ in 0 ..< Int((seconds / deviceMotion.updateInterval).rounded()) {
            deviceMotion.setCurrentDeviceRotation(to: attitude)
        }
    }

    /// A tilt that has just ended must not be snatched back. A single settling stage moves fastest at exactly this moment, which is what read as the view being pulled away the instant the device stopped; two stages start from a standstill instead.
    func testATurnJustReleasedBarelyMovesAtFirst() {
        deviceMotion.setUpdateInterval(Self.interval)
        settle(in: .portrait, at: .identity, thenMoveTo: Quat(angle: .degrees(20), axis: .xAxis))

        hold(Quat(angle: .degrees(20), axis: .xAxis), seconds: 0.3)

        XCTAssertGreaterThan(deviceMotion.deltaRotation.angle.degrees, 19, "the view was pulled back too quickly after the tilt ended")
    }

    /// The point of the settling: a turn the device makes and then keeps is given up rather than held against it forever. It has to go one way only, never turning back past rest and returning, which is what a second stage would do if it were sprung rather than chasing.
    func testAHeldTurnDecaysWithoutTurningBack() {
        deviceMotion.setUpdateInterval(Self.interval)
        settle(in: .portrait, at: .identity, thenMoveTo: Quat(angle: .degrees(20), axis: .xAxis))

        var previous = deviceMotion.deltaRotation.pitch.degrees
        for _ in 0 ..< 30 {
            hold(Quat(angle: .degrees(20), axis: .xAxis), seconds: 0.5)
            let current = deviceMotion.deltaRotation.pitch.degrees

            XCTAssertLessThan(current, previous, "the turn stopped being given up")
            XCTAssertGreaterThan(current, -0.5, "the turn was given up past rest and came back the other way")
            previous = current
        }
    }

    /// Held long enough, the device has to come all the way back to rest. Anything left over is a view sitting permanently off centre.
    func testAHeldTurnEventuallyComesBackToRest() {
        deviceMotion.setUpdateInterval(Self.interval)
        settle(in: .portrait, at: .identity, thenMoveTo: Quat(angle: .degrees(20), axis: .xAxis))

        hold(Quat(angle: .degrees(20), axis: .xAxis), seconds: Self.settlingDuration * 12)

        XCTAssertEqual(deviceMotion.deltaRotation.angle.degrees, 0, accuracy: 0.1)
    }

    /// Returning the device to where it started after a held turn has to read as a turn the other way, by as much as was given up. Otherwise putting the device back would leave the view where it was rather than moving it.
    func testReturningAfterAHeldTurnReadsAsATurnTheOtherWay() {
        deviceMotion.setUpdateInterval(Self.interval)
        settle(in: .portrait, at: .identity, thenMoveTo: Quat(angle: .degrees(20), axis: .xAxis))
        hold(Quat(angle: .degrees(20), axis: .xAxis), seconds: Self.settlingDuration * 12)

        deviceMotion.setCurrentDeviceRotation(to: .identity)

        XCTAssertEqual(deviceMotion.deltaRotation.pitch.degrees, -20, accuracy: 0.2)
    }

    /// Every stage moves by a fraction of whatever gap is left, so the settling must not depend on the sample rate. Both rates have to land on the curve two stages in series describe, `(1 + t/τ) * e^-(t/τ)` of the turn left after time `t`, which is `2/e` of it after one settling duration.
    ///
    /// They land near it rather than on it: stepping a curve in finite samples undershoots slightly, and more so the coarser the steps. A tenth of a degree either side of half a degree is that, not a rate the settling actually runs at.
    func testTheSettlingDoesNotDependOnTheSampleRate() {
        for interval in [Self.interval, 1 / 10.0] {
            deviceMotion.setUpdateInterval(interval)
            settle(in: .portrait, at: .identity, thenMoveTo: Quat(angle: .degrees(20), axis: .xAxis))
            hold(Quat(angle: .degrees(20), axis: .xAxis), seconds: Self.settlingDuration)

            XCTAssertEqual(
                deviceMotion.deltaRotation.angle.degrees,
                20 * 2 * exp(-1),
                accuracy: 0.8,
                "an interval of \(interval) settled at the wrong rate"
            )
        }
    }

    /// The duration is settable while updates are running, so it has to take effect from the next sample rather than at the next reset. A shorter one gives up more of a held turn over the same stretch of time.
    func testAShorterSettlingDurationGivesUpAHeldTurnFaster() {
        func remainingAfterTwoSeconds(settlingDuration: TimeInterval) -> Double {
            deviceMotion.setSettlingDuration(settlingDuration)
            settle(in: .portrait, at: .identity, thenMoveTo: Quat(angle: .degrees(20), axis: .xAxis))
            hold(Quat(angle: .degrees(20), axis: .xAxis), seconds: 2)

            return deviceMotion.deltaRotation.angle.degrees
        }

        deviceMotion.setUpdateInterval(Self.interval)

        XCTAssertLessThan(
            remainingAfterTwoSeconds(settlingDuration: 0.5),
            remainingAfterTwoSeconds(settlingDuration: 4),
            "the shorter duration did not give up more of the turn"
        )
    }

    /// A duration of zero or less has no rate to settle at. It has to stop the settling and hold the turn rather than divide by it, which would take the settled rotation to somewhere that is not a rotation at all.
    func testANonPositiveSettlingDurationStopsTheSettling() {
        for settlingDuration in [0.0, -2.0] {
            deviceMotion.setUpdateInterval(Self.interval)
            deviceMotion.setSettlingDuration(settlingDuration)
            settle(in: .portrait, at: .identity, thenMoveTo: Quat(angle: .degrees(20), axis: .xAxis))

            hold(Quat(angle: .degrees(20), axis: .xAxis), seconds: 10)

            XCTAssertEqual(
                deviceMotion.deltaRotation.angle.degrees,
                20,
                accuracy: 1e-9,
                "a settling duration of \(settlingDuration) did not hold the turn"
            )
        }
    }

    // MARK: - Interface to world rotation

    /// Where locked content ends up in the world, given the rotation the effect applies on screen.
    ///
    /// The effect returns a screen-frame rotation, so it is taken back to the device frame, re-expressed about the interface's axes, and finally carried out into the world by the device's own attitude. Whatever the device is doing has to drop out along the way: that is what being locked to the real world means.
    private func worldOrientation(attitude: Quat, offset: Quat, isShowingInFourDirections: Bool = false) -> Quat {
        deviceMotion.setCurrentDeviceRotation(to: attitude)
        let screenRotation = deviceMotion.interfaceToWorldRotation(offset: offset, isShowingInFourDirections: isShowingInFourDirections)
        let interfaceRotation = deviceMotion.interfaceRotation

        return attitude * interfaceRotation * screenRotation.screenToDeviceReferenceFrame * interfaceRotation.inverse
    }

    private static let offset = Quat(pitch: .degrees(90), yaw: .degrees(30), localRoll: .zero)

    /// The point of the effect: content pinned to a real world angle stays at that angle however the device is held. The attitude has to cancel exactly, in every interface orientation.
    ///
    /// This is the invariant that broke when the interface rotation was applied on the wrong side of the attitude, which left content drifting as the device turned rather than staying put.
    func testTheDeviceAttitudeCancelsOutOfARealWorldLock() {
        for orientation in UIInterfaceOrientation.allShowable {
            _ = deviceMotion.setInterfaceOrientation(orientation)

            let reference = worldOrientation(attitude: Attitude.spread[0].attitude, offset: Self.offset)

            for (name, attitude) in Attitude.spread.dropFirst() {
                assertSameRotation(
                    worldOrientation(attitude: attitude, offset: Self.offset),
                    reference,
                    "content moved in the world when the device was \(name), in \(orientation.testName)"
                )
            }
        }
    }

    /// The anchor for the invariant above, which on its own only says the result is constant and not that it is the right constant. In portrait the content lands on exactly the angle that was asked for.
    func testAPortraitLockLandsOnExactlyTheRequestedOffset() {
        _ = deviceMotion.setInterfaceOrientation(.portrait)

        for (name, attitude) in Attitude.spread {
            assertSameRotation(
                worldOrientation(attitude: attitude, offset: Self.offset),
                Self.offset,
                "content was not at the requested offset when the device was \(name)"
            )
        }
    }

    /// Showing in four directions turns the locked content about the world's vertical to face the viewer. Two things have to hold everywhere, including on the boundaries themselves: it turns about the vertical and nothing else, and it turns by a whole quarter turn. Anything else leaves the copy tipped out of the world rather than square to the device.
    func testFourDirectionsTurnsTheLockedContentByAQuarterTurnAboutTheWorldVertical() {
        for orientation in UIInterfaceOrientation.allShowable {
            _ = deviceMotion.setInterfaceOrientation(orientation)

            /// Fives rather than a round step, so the sweep lands on the boundaries at forty five degrees as well as between them.
            for bearing in stride(from: 0.0, to: 360.0, by: 5.0) {
                let attitude = Attitude.pointing(bearing: .degrees(bearing))

                let locked = worldOrientation(attitude: attitude, offset: Self.offset)
                let facing = worldOrientation(attitude: attitude, offset: Self.offset, isShowingInFourDirections: true)
                let turn = facing * locked.inverse
                let where_ = "at bearing \(bearing) in \(orientation.testName)"

                let turned = turn.angle.degrees
                XCTAssertEqual(turned, (turned / 90).rounded() * 90, accuracy: 1e-6, "\(where_) the turn was not a whole quarter turn")

                /// A turn of nothing has no axis to check, and asking for one divides by its own zero length.
                if turned > 1e-6 {
                    XCTAssertEqual(abs(turn.axis.z), 1, accuracy: 1e-9, "\(where_) the turn was not about the world vertical")
                }
            }
        }
    }

    /// The quarter turn snaps to whichever axis the device is pointing closest to, measured from the top of the *interface* rather than the top of the device. The two are ninety degrees apart in landscape, which is where content used to end up facing the wrong way.
    ///
    /// Both parts matter: which quadrant is chosen, and that the boundaries sit at forty five degrees rather than on the axes themselves.
    func testTheFourDirectionQuarterTurnIsMeasuredFromTheTopOfTheInterface() {
        for orientation in UIInterfaceOrientation.allShowable {
            _ = deviceMotion.setInterfaceOrientation(orientation)
            let interfaceAngle = deviceMotion.interfaceRotation.roll.degrees

            /// Five degrees inside each side of every boundary, so a boundary in the wrong place shows up as well as a quadrant in the wrong order. The boundaries themselves are left out: which of the two neighbouring quadrants a device pointing exactly between them lands in is arbitrary, and pinning it here would be pinning a coin toss.
            for bearing in stride(from: -40.0, to: 360.0, by: 10.0) {
                let attitude = Attitude.pointing(bearing: .degrees(bearing))

                let locked = worldOrientation(attitude: attitude, offset: Self.offset)
                let facing = worldOrientation(attitude: attitude, offset: Self.offset, isShowingInFourDirections: true)

                /// The bearing the device points, relative to where the interface's own top is.
                let relativeBearing = bearing - interfaceAngle
                let expected = Quat(angle: .degrees((relativeBearing / 90).rounded() * 90), axis: .zAxis)

                assertSameRotation(
                    facing * locked.inverse,
                    expected,
                    accuracy: .degrees(1e-6),
                    "wrong quadrant at bearing \(bearing) in \(orientation.testName)"
                )
            }
        }
    }

    /// The clone rotation snaps between four values, and the effect suppresses its smoothing animation on the update where it moves. Reporting a change that did not happen makes every update jump instead of easing; missing one sweeps the content the long way round to its new quadrant.
    func testTheFourDirectionChangeFlagReportsOnlyBoundaryCrossings() {
        _ = deviceMotion.setInterfaceOrientation(.portrait)

        /// Either side of the boundary at forty five degrees.
        deviceMotion.setCurrentDeviceRotation(to: Attitude.pointing(bearing: .degrees(40)))
        deviceMotion.setCurrentDeviceRotation(to: Attitude.pointing(bearing: .degrees(44)))
        XCTAssertFalse(deviceMotion.cloneRotationDidChange, "reported a change while inside one quadrant")

        deviceMotion.setCurrentDeviceRotation(to: Attitude.pointing(bearing: .degrees(50)))
        XCTAssertTrue(deviceMotion.cloneRotationDidChange, "did not report crossing into the next quadrant")

        deviceMotion.setCurrentDeviceRotation(to: Attitude.pointing(bearing: .degrees(80)))
        XCTAssertFalse(deviceMotion.cloneRotationDidChange, "reported a change while inside the next quadrant")
    }

    /// Lying flat is the resting case and has to land exactly on identity. A clone rotation that was merely very close to it would report a change on every update that passed through this quadrant, and the effect would refuse to animate the whole time.
    func testTheFlatQuadrantsCloneRotationIsExactlyIdentity() {
        _ = deviceMotion.setInterfaceOrientation(.portrait)
        deviceMotion.setCurrentDeviceRotation(to: Attitude.pointing(bearing: .degrees(0)))

        XCTAssertEqual(deviceMotion.cloneRotation, .identity)
    }
}
