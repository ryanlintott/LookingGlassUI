//
//  WindowSceneReader.swift
//  LookingGlassUI
//
//  Created by Ryan Lintott on 2026-09-02.
//

import Combine
import SwiftUI

/// What a scene reports about itself.
struct WindowSceneState: Equatable {
    /// The orientation the scene's interface is showing, or `nil` when the scene cannot say which way it is facing.
    let interfaceOrientation: UIInterfaceOrientation?

    /// Whether the scene is showing on the device's own screen rather than on an external display.
    let isOnDeviceScreen: Bool
}

/// Reports what the scene these views are in says about itself.
///
/// Interface orientation belongs to a window scene. Reaching it through `UIApplication.connectedScenes` means picking a scene out of all of them and hoping it is the one whose views are asking, which is wrong for a scene on an external display and arbitrary when more than one is open. A view already sits in exactly one scene, so it is asked directly.
///
/// The orientation is what the interface is facing, unlike `UIDevice.current.orientation`, which reports where the device is physically pointing. That is unknown at launch and face up or face down whenever the device is lying flat, none of which say which way the interface is facing.
struct WindowSceneReader: UIViewRepresentable {
    /// Called with what the scene says about itself whenever it may have changed.
    let onChange: (WindowSceneState) -> Void

    func makeUIView(context: Context) -> ReaderView {
        let view = ReaderView()
        view.onChange = onChange
        return view
    }

    func updateUIView(_ uiView: ReaderView, context: Context) {
        uiView.onChange = onChange
    }

    /// A view that reads the state of the scene it is in.
    final class ReaderView: UIView {
        var onChange: ((WindowSceneState) -> Void)?

        /// Whether a report is already under way or waiting to be made.
        ///
        /// Reporting refreshes the scene's views, and laying those out calls straight back into ``setNeedsWindowSceneReport()``. This is what stops that becoming a loop. It terminates without this only because ``MotionManager/setWindowSceneState(_:)`` drops a value that hasn't changed, and that is a guarantee living in another type.
        ///
        /// Coalescing several triggers in one pass is a side benefit rather than the reason. Little arrives to coalesce now that a report is prompted by a layout or a device turn rather than by every motion update.
        private var isReportScheduled = false

        /// Ends with this view, so a closed scene stops listening without anything having to be told.
        private var orientationChanges: AnyCancellable?

        override init(frame: CGRect) {
            super.init(frame: frame)

            /// A half turn of the interface leaves every size and every trait unchanged, so it causes no layout and nothing in the view hierarchy notices it. The device turning is the one signal that does arrive, so it is what prompts a fresh read.
            ///
            /// The device orientation itself is never read. `UIDevice.orientation` is documented to report `unknown` unless device orientation notifications are being generated; this only uses the notification as a prompt to ask the window scene which way its interface is facing, which is a separate value with no such caveat.
            ///
            /// Received on the main queue because a notification carries no isolation of its own, and everything below it belongs to the main actor.
            orientationChanges = NotificationCenter.default
                .publisher(for: UIDevice.orientationDidChangeNotification)
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.setNeedsWindowSceneReport()
                }
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        /// A view has no scene to ask until it reaches a window.
        override func didMoveToWindow() {
            super.didMoveToWindow()

            setNeedsWindowSceneReport()
        }

        /// Turning the interface a quarter turn swaps its width and height, so everything in it is laid out again. Kept alongside the notification above so a quarter turn is still caught in an app where device orientation notifications are not being generated.
        override func layoutSubviews() {
            super.layoutSubviews()

            setNeedsWindowSceneReport()
        }

        /// Arranges for the scene to be read on the next turn of the main actor rather than reading it now.
        ///
        /// SwiftUI lays out the views it hosts as part of its own update, so every hook that leads here can run inside one. Reporting from inside an update publishes a change while views are being evaluated, which SwiftUI rejects as undefined behaviour.
        private func setNeedsWindowSceneReport() {
            guard !isReportScheduled else { return }

            isReportScheduled = true
            Task { @MainActor [weak self] in
                guard let self else { return }

                /// Cleared after the report rather than before it, so that whatever the report sets off cannot schedule another one while it is still running. See ``isReportScheduled``.
                self.reportWindowSceneState()
                self.isReportScheduled = false
            }
        }

        /// Reads the scene this view is in and reports what it says.
        private func reportWindowSceneState() {
            guard let windowScene = window?.windowScene else { return }

            let interfaceOrientation: UIInterfaceOrientation
            if #available(iOS 16.0, *) {
                interfaceOrientation = windowScene.effectiveGeometry.interfaceOrientation
            } else {
                interfaceOrientation = windowScene.interfaceOrientation
            }

            onChange?(
                WindowSceneState(
                    /// A scene that cannot say which way it is facing reports nothing rather than resetting the world to portrait, leaving the last known orientation in place.
                    interfaceOrientation: interfaceOrientation == .unknown ? nil : interfaceOrientation,
                    /// `UIScreen.main` is deprecated and has no replacement, because Apple's answer to "which screen am I on" is `windowScene.screen` and there is no longer any answer to "which screen is built into the device". This asks the second question, so the deprecated property is the only thing that answers it.
                    ///
                    /// The alternative is the scene's session role, which is not enough: the external display roles cover the older non-interactive second screen, while a window dragged onto an external display under Stage Manager is an ordinary `.windowApplication` scene. That check would pass exactly the case most likely to arise.
                    ///
                    /// A scene can move between screens while it is open, so this is read on every report rather than settled once.
                    isOnDeviceScreen: windowScene.screen === UIScreen.main
                )
            )
        }
    }
}
