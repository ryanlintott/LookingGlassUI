//
//  WindowDebugBar.swift
//  LookingGlassUIExample
//
//  Created by Ryan Lintott on 2026-09-03.
//

import LookingGlassUI
import SwiftUI

/// Shows what one window knows about itself, and opens another one beside it.
///
/// Everything in this package is per scene, and the cases that are easiest to get wrong only appear with more than one window open: whether each window turns about its own centre, whether two windows agree on the interface orientation after a half turn, and whether a window moved to an external display stops running effects. All of those need two windows side by side and a way to tell them apart.
struct WindowDebugBar: View {
    @EnvironmentObject private var motionManager: MotionManager

    /// Distinguishes this window from the others, so two side by side can be told apart in a screenshot or a photograph.
    let windowID: String

    /// False on a device that only ever shows one window, where the button below would do nothing.
    private var supportsMultipleWindows: Bool {
        UIApplication.shared.supportsMultipleScenes
    }

    var body: some View {
        HStack(spacing: 12) {
            Text(windowID)
                .font(.system(.caption, design: .monospaced))
                .bold()
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.accentColor.opacity(0.2)))

            Text(motionManager.interfaceOrientation?.debugName ?? "no orientation")
                .font(.caption)

            Spacer()

            Image(systemName: motionManager.isDetectingMotion ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(motionManager.isDetectingMotion ? .green : .secondary)
                .accessibilityLabel(motionManager.isDetectingMotion ? "Detecting motion" : "Not detecting motion")

            if supportsMultipleWindows {
                Button {
                    /// Soft-deprecated in favour of `activateSceneSessionForRequest:`, which needs iOS 17. This app runs from iOS 15, and it is only a test harness, so the older call is used rather than carrying both.
                    UIApplication.shared.requestSceneSessionActivation(nil, userActivity: nil, options: nil, errorHandler: { print("Could not open another window: \($0.localizedDescription)") })
                } label: {
                    Label {
                        Text("New Window")
                    } icon: {
                        Image(systemName: "plus.rectangle.on.rectangle")
                    }
                }
                .accessibilityLabel("Open another window")
            }
        }
        .padding(.horizontal)
    }
}

extension UIInterfaceOrientation {
    /// A short name for showing on screen while testing.
    var debugName: String {
        switch self {
        case .portrait: return "Portrait"
        case .portraitUpsideDown: return "Upside down"
        case .landscapeLeft: return "Landscape L"
        case .landscapeRight: return "Landscape R"
        case .unknown: return "Unknown"
        @unknown default: return "Unrecognised"
        }
    }
}

struct WindowDebugBar_Previews: PreviewProvider {
    static var previews: some View {
        WindowDebugBar(windowID: "A1B2")
            .motionManager(disabled: true)
    }
}
