//
//  Typography.swift
//  Recito
//
//  SF system typography. Reading text is user-scalable and far larger than
//  system body; timers use tabular figures. Reading-font helpers take explicit
//  parameters so they can be driven by DisplaySettings (added later).
//

import SwiftUI

enum Typography {
    // Reading text scales within this range via the in-app Text-size control.
    static let readingMinSize: CGFloat = 28
    static let readingMaxSize: CGFloat = 64
    static let readingDefaultSize: CGFloat = 40

    /// Body / list-row reading font for the teleprompter, honoring typeface + bold.
    static func reading(size: CGFloat, serif: Bool, bold: Bool) -> Font {
        .system(size: size, weight: bold ? .semibold : .regular, design: serif ? .serif : .default)
    }

    // Chrome / UI roles
    static let wordmark = Font.system(size: 30, weight: .bold)        // "Recito"
    static let navTitle = Font.system(size: 24, weight: .bold)        // screen/talk title
    static let cardTitle = Font.system(size: 17, weight: .semibold)   // talk card title
    static let body = Font.body
    static let tag = Font.system(size: 13, weight: .semibold)         // mode tag / pill
    static let groupHeader = Font.footnote.weight(.semibold)          // ALL-CAPS group header

    /// Tabular figures for timers / numerals.
    static let timer = Font.system(size: 19, weight: .bold).monospacedDigit()
}
