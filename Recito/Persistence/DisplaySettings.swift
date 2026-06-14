//
//  DisplaySettings.swift
//  Recito
//
//  App-wide typography + appearance, persisted to UserDefaults. Backed by
//  @Published (not @AppStorage) so every observer — readers and the Aa sheet —
//  live-updates together. These are the controls behind the Aa button.
//

import SwiftUI
import Combine

enum Typeface: String, CaseIterable, Identifiable {
    case system, serif
    var id: String { rawValue }
    var label: String { self == .system ? "System" : "Serif" }
    var isSerif: Bool { self == .serif }
}

enum AppTheme: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String { rawValue.capitalized }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

final class DisplaySettings: ObservableObject {
    private enum Key {
        static let typeface = "settings.typeface"
        static let textScale = "settings.textScale"
        static let lineSpacingScale = "settings.lineSpacingScale"
        static let boldText = "settings.boldText"
        static let theme = "settings.theme"
        static let keepAwake = "settings.keepAwake"
        static let autoScrollSpeed = "settings.autoScrollSpeed"
        static let defaultTimeLimit = "settings.defaultTimeLimit"
        static let recognitionLanguage = "settings.recognitionLanguage"
        static let autoOpenScripture = "settings.autoOpenScripture"
        static let showVoiceDebug = "settings.showVoiceDebug"
    }

    /// Voice-follow recognition languages (label, BCP-47 identifier).
    static let recognitionLanguages: [(label: String, id: String)] = [
        ("Español", "es-ES"),
        ("Español (México)", "es-MX"),
        ("English (US)", "en-US"),
        ("English (UK)", "en-GB"),
    ]

    private let defaults: UserDefaults

    // Sliders are stored 0...1 and mapped to concrete values via the helpers below.
    @Published var typeface: Typeface { didSet { defaults.set(typeface.rawValue, forKey: Key.typeface) } }
    @Published var textScale: Double { didSet { defaults.set(textScale, forKey: Key.textScale) } }
    @Published var lineSpacingScale: Double { didSet { defaults.set(lineSpacingScale, forKey: Key.lineSpacingScale) } }
    @Published var boldText: Bool { didSet { defaults.set(boldText, forKey: Key.boldText) } }
    @Published var theme: AppTheme { didSet { defaults.set(theme.rawValue, forKey: Key.theme) } }
    @Published var keepAwake: Bool { didSet { defaults.set(keepAwake, forKey: Key.keepAwake) } }
    @Published var autoScrollSpeed: Double { didSet { defaults.set(autoScrollSpeed, forKey: Key.autoScrollSpeed) } }
    /// Default talk time limit in seconds (used for new imports).
    @Published var defaultTimeLimit: TimeInterval { didSet { defaults.set(defaultTimeLimit, forKey: Key.defaultTimeLimit) } }
    /// BCP-47 language used for voice-follow recognition (Spanish-first).
    @Published var recognitionLanguage: String { didSet { defaults.set(recognitionLanguage, forKey: Key.recognitionLanguage) } }
    /// Auto-open the reference app at a scripture as you approach it (off by
    /// default; otherwise the cue is glance-only and you tap to open).
    @Published var autoOpenScripture: Bool { didSet { defaults.set(autoOpenScripture, forKey: Key.autoOpenScripture) } }
    /// Show the voice-follow diagnostics overlay (recognized words, predictor
    /// lead, pace). Debug builds only — the toggle and overlay are compiled out
    /// of release, so this value is inert there.
    @Published var showVoiceDebug: Bool { didSet { defaults.set(showVoiceDebug, forKey: Key.showVoiceDebug) } }

    /// Pacing presets in minutes. Configurable, not hardcoded (PRD).
    let pacingPresets: [Int] = [10, 15, 30, 45, 60]

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        typeface = Typeface(rawValue: defaults.string(forKey: Key.typeface) ?? "") ?? .system
        textScale = defaults.object(forKey: Key.textScale) as? Double ?? 0.4
        lineSpacingScale = defaults.object(forKey: Key.lineSpacingScale) as? Double ?? 0.45
        boldText = defaults.bool(forKey: Key.boldText)
        theme = AppTheme(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .system
        keepAwake = defaults.object(forKey: Key.keepAwake) as? Bool ?? true
        autoScrollSpeed = defaults.object(forKey: Key.autoScrollSpeed) as? Double ?? 0.5
        defaultTimeLimit = defaults.object(forKey: Key.defaultTimeLimit) as? Double ?? 30 * 60
        recognitionLanguage = defaults.string(forKey: Key.recognitionLanguage) ?? "es-ES"
        autoOpenScripture = defaults.bool(forKey: Key.autoOpenScripture)
        showVoiceDebug = defaults.bool(forKey: Key.showVoiceDebug)
    }

    // MARK: - Derived reading values

    /// Mapped reading font size in points (~28–64) for the current text scale.
    var readingFontSize: CGFloat {
        let range = Typography.readingMaxSize - Typography.readingMinSize
        return Typography.readingMinSize + range * CGFloat(textScale)
    }

    /// Extra line spacing in points (0...22) for the current line-spacing scale.
    var readingLineSpacing: CGFloat {
        22 * CGFloat(lineSpacingScale)
    }

    /// Multiplier around the time-paced auto-scroll velocity. Default slider
    /// (0.5) → 1.0× (finish exactly at the time limit); range ~0.5×…1.5×.
    var autoScrollMultiplier: CGFloat {
        0.5 + CGFloat(autoScrollSpeed)
    }

    func readingFont(scaledBy factor: CGFloat = 1) -> Font {
        Typography.reading(size: readingFontSize * factor, serif: typeface.isSerif, bold: boldText)
    }
}
