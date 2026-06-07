//
//  Theme.swift
//  Recito
//
//  Semantic color tokens for the locked `pal-ios` palette. We prefer SwiftUI
//  system colors — they already match the design's hex values and handle
//  light/dark + increased-contrast automatically.
//

import SwiftUI

enum Theme {
    // Backgrounds / surfaces
    static let bg = Color(uiColor: .systemGroupedBackground)            // #F2F2F7 / #000000
    static let surface = Color(uiColor: .secondarySystemGroupedBackground) // #FFFFFF / #1C1C1E
    static let surface2 = Color(uiColor: .systemGray5)                 // #E5E5EA / #2C2C2E
    static let surface3 = Color(uiColor: .systemGray4)                 // #D1D1D6 / #3A3A3C

    // Text (ink)
    static let ink = Color(uiColor: .label)                            // primary
    static let ink2 = Color(uiColor: .secondaryLabel)                  // secondary
    static let ink3 = Color(uiColor: .tertiaryLabel)                   // tertiary

    static let separator = Color(uiColor: .separator)

    // Brand: the single accent (system blue) carries every primary action,
    // the pace marker, the scripture cue, and the current-line indicator.
    static let accent = Color.accentColor
    static let onAccent = Color.white

    /// On-pace state.
    static let good = Color(uiColor: .systemGreen)             // #34C759 / #30D158
    /// "Behind" pace warning (you'll run over your time).
    static let warning = Color(uiColor: .systemOrange)

    /// Current-row / current-line tint. Slightly stronger in dark mode.
    static func accentSoft(_ scheme: ColorScheme) -> Color {
        Color.accentColor.opacity(scheme == .dark ? 0.18 : 0.12)
    }
}
