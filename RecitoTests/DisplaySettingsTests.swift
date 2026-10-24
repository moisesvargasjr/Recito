//
//  DisplaySettingsTests.swift
//  RecitoTests
//

import Testing
import Foundation
import SwiftUI
@testable import Recito

@MainActor
struct DisplaySettingsTests {
    private func reload(_ iso: IsolatedDefaults) -> DisplaySettings {
        DisplaySettings(defaults: iso.defaults)
    }

    @Test func defaults() {
        let iso = IsolatedDefaults()
        defer { iso.tearDown() }
        let s = reload(iso)
        #expect(s.typeface == .system)
        #expect(s.textScale == 0.4)
        #expect(s.lineSpacingScale == 0.45)
        #expect(!s.boldText)
        #expect(s.theme == .system)
        #expect(s.keepAwake)
        #expect(s.autoScrollSpeed == 0.5)
        #expect(s.defaultTimeLimit == 1800)
        #expect(s.recognitionLanguage == "es-ES")
        #expect(!s.autoOpenScripture)
        #expect(!s.showVoiceDebug)
        #expect(s.pacingPresets == [10, 15, 30, 45, 60])
        #expect(s.scriptureDestination == .jwLibrary)
    }

    @Test func scriptureDestinationPersistsAndToleratesUnknownValues() {
        let iso = IsolatedDefaults()
        defer { iso.tearDown() }
        reload(iso).scriptureDestination = .inApp
        #expect(reload(iso).scriptureDestination == .inApp)
        iso.defaults.set("carrier-pigeon", forKey: "settings.scriptureDestination")
        #expect(reload(iso).scriptureDestination == .jwLibrary)
    }

    @Test func scriptureDestinationLabels() {
        #expect(ScriptureDestination.allCases == [.jwLibrary, .inApp])
        #expect(ScriptureDestination.jwLibrary.label == "JW Library app")
        #expect(ScriptureDestination.inApp.label == "In Recito")
    }

    @Test func everyPropertyPersistsAcrossReload() {
        let iso = IsolatedDefaults()
        defer { iso.tearDown() }
        let s = reload(iso)
        s.typeface = .serif
        s.textScale = 0.9
        s.lineSpacingScale = 0.1
        s.boldText = true
        s.theme = .dark
        s.keepAwake = false
        s.autoScrollSpeed = 0.75
        s.defaultTimeLimit = 600
        s.recognitionLanguage = "en-US"
        s.autoOpenScripture = true
        s.showVoiceDebug = true

        let r = reload(iso)
        #expect(r.typeface == .serif)
        #expect(r.textScale == 0.9)
        #expect(r.lineSpacingScale == 0.1)
        #expect(r.boldText)
        #expect(r.theme == .dark)
        #expect(!r.keepAwake)
        #expect(r.autoScrollSpeed == 0.75)
        #expect(r.defaultTimeLimit == 600)
        #expect(r.recognitionLanguage == "en-US")
        #expect(r.autoOpenScripture)
        #expect(r.showVoiceDebug)
    }

    @Test func invalidStoredEnumsFallBackToDefaults() {
        let iso = IsolatedDefaults()
        defer { iso.tearDown() }
        iso.defaults.set("comic-sans", forKey: "settings.typeface")
        iso.defaults.set("neon", forKey: "settings.theme")
        let s = reload(iso)
        #expect(s.typeface == .system)
        #expect(s.theme == .system)
    }

    @Test func instancesWithSeparateDefaultsDoNotShareState() {
        let a = IsolatedDefaults()
        let b = IsolatedDefaults()
        defer { a.tearDown(); b.tearDown() }
        reload(a).boldText = true
        #expect(!reload(b).boldText)
    }

    @Test func readingFontSizeSpansTheTypographyRange() {
        let iso = IsolatedDefaults()
        defer { iso.tearDown() }
        let s = reload(iso)
        s.textScale = 0
        #expect(s.readingFontSize == Typography.readingMinSize)
        s.textScale = 1
        #expect(s.readingFontSize == Typography.readingMaxSize)
        s.textScale = 0.5
        #expect(s.readingFontSize == (Typography.readingMinSize + Typography.readingMaxSize) / 2)
    }

    @Test func lineSpacingMapsZeroToTwentyTwo() {
        let iso = IsolatedDefaults()
        defer { iso.tearDown() }
        let s = reload(iso)
        s.lineSpacingScale = 0
        #expect(s.readingLineSpacing == 0)
        s.lineSpacingScale = 1
        #expect(s.readingLineSpacing == 22)
    }

    @Test func autoScrollMultiplierRunsHalfToOneAndAHalf() {
        let iso = IsolatedDefaults()
        defer { iso.tearDown() }
        let s = reload(iso)
        #expect(s.autoScrollMultiplier == 1)
        s.autoScrollSpeed = 0
        #expect(s.autoScrollMultiplier == 0.5)
        s.autoScrollSpeed = 1
        #expect(s.autoScrollMultiplier == 1.5)
    }

    @Test func readingFontBuildsForEveryStyleCombination() {
        let iso = IsolatedDefaults()
        defer { iso.tearDown() }
        let s = reload(iso)
        for face in Typeface.allCases {
            for bold in [false, true] {
                s.typeface = face
                s.boldText = bold
                #expect(s.readingFont(scaledBy: 1.4) == Typography.reading(size: s.readingFontSize * 1.4, serif: face.isSerif, bold: bold))
            }
        }
        s.typeface = .serif
        s.boldText = true
        #expect(s.readingFont() == Typography.reading(size: s.readingFontSize, serif: true, bold: true))
    }

    @Test func typefaceAndThemeMetadata() {
        #expect(Typeface.system.label == "System")
        #expect(Typeface.serif.label == "Serif")
        #expect(Typeface.serif.isSerif)
        #expect(!Typeface.system.isSerif)
        #expect(Typeface.serif.id == "serif")
        #expect(AppTheme.system.colorScheme == nil)
        #expect(AppTheme.light.colorScheme == .light)
        #expect(AppTheme.dark.colorScheme == .dark)
        #expect(AppTheme.dark.label == "Dark")
        #expect(AppTheme.light.id == "light")
    }

    @Test func recognitionLanguagesIncludeTheDefault() {
        let ids = DisplaySettings.recognitionLanguages.map(\.id)
        #expect(ids.contains("es-ES"))
        #expect(Set(ids).count == ids.count)
    }
}
