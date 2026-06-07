//
//  KeepAwake.swift
//  Recito
//
//  Keeps the screen awake while reading (the speaker shouldn't have the display
//  dim mid-talk). Driven by the "Keep screen awake" setting.
//

import SwiftUI
import UIKit

private struct KeepAwakeModifier: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        content
            .onAppear { UIApplication.shared.isIdleTimerDisabled = enabled }
            .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
            .onChange(of: enabled) { newValue in
                UIApplication.shared.isIdleTimerDisabled = newValue
            }
    }
}

extension View {
    /// Disable the idle timer while this view is on screen, if `enabled`.
    func keepAwake(_ enabled: Bool) -> some View {
        modifier(KeepAwakeModifier(enabled: enabled))
    }
}
