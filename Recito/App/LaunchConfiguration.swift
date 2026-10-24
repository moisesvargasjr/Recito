//
//  LaunchConfiguration.swift
//  Recito
//
//  Launch-argument contract used by UI tests (and manual QA). Parsing is a pure
//  function of arguments + environment so it can be unit-tested; unknown
//  arguments are ignored so system flags (-NSDoubleLocalizedStrings, ...) pass.
//
//    -uitest                       isolated storage, fake speech, test hooks
//    -reset                        wipe the isolated UI-test state first
//    -seed <fixture>               samples|empty|longScript|outline|many|mixedHidden
//    -speech <mode>                fake|unavailable|live (fake under -uitest)
//    -chromeHideDelay <seconds>    reader chrome auto-hide delay (default 3.5)
//    -noAnimations                 disable UIKit animations
//    -theme <light|dark>           force the appearance
//    -openTalk <uuid>              open this talk's reader at launch
//  Environment: RECITO_FAKE_SPEECH_WORDS="word word ..." scripts the fake source.
//

import Foundation

/// Named library contents for UI tests (talks are built in UITestFixtures.swift).
nonisolated enum UITestFixture: String, CaseIterable, Equatable {
    case samples, empty, longScript, outline, many, mixedHidden
}

nonisolated enum SpeechMode: Equatable {
    case live, fake, unavailable
}

nonisolated struct LaunchConfiguration: Equatable {
    static let defaultChromeHideDelay: TimeInterval = 3.5
    static let fakeSpeechWordsKey = "RECITO_FAKE_SPEECH_WORDS"

    var isUITest = false
    var resetState = false
    var fixture: UITestFixture?
    var speech: SpeechMode = .live
    var chromeHideDelay: TimeInterval = LaunchConfiguration.defaultChromeHideDelay
    var disableAnimations = false
    var theme: AppTheme?
    var openTalkID: String?
    var fakeSpeechWords: [String] = []

    /// Release builds ignore every launch flag so test hooks can't change a
    /// shipping app's behavior.
    static func parse(arguments: [String], environment: [String: String]) -> LaunchConfiguration {
        #if DEBUG
        return parseFlags(arguments: arguments, environment: environment)
        #else
        return LaunchConfiguration()
        #endif
    }

    private static func parseFlags(arguments: [String], environment: [String: String]) -> LaunchConfiguration {
        var config = LaunchConfiguration()
        var explicitSpeech: SpeechMode?
        var index = 0
        while index < arguments.count {
            let value = index + 1 < arguments.count ? arguments[index + 1] : nil
            var consumed = 0
            switch arguments[index] {
            case "-uitest": config.isUITest = true
            case "-reset": config.resetState = true
            case "-noAnimations": config.disableAnimations = true
            case "-seed":
                config.fixture = value.flatMap(UITestFixture.init(rawValue:))
                consumed = 1
            case "-speech":
                explicitSpeech = value.flatMap(parseSpeech)
                consumed = 1
            case "-chromeHideDelay":
                config.chromeHideDelay = value.flatMap(parseDelay) ?? defaultChromeHideDelay
                consumed = 1
            case "-theme":
                config.theme = value.flatMap(parseTheme)
                consumed = 1
            case "-openTalk":
                config.openTalkID = value
                consumed = 1
            default: break
            }
            index += 1 + consumed
        }
        config.speech = explicitSpeech ?? (config.isUITest ? .fake : .live)
        config.fakeSpeechWords = (environment[fakeSpeechWordsKey] ?? "")
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
        return config
    }

    private static func parseSpeech(_ value: String) -> SpeechMode? {
        switch value {
        case "fake": return .fake
        case "unavailable": return .unavailable
        case "live": return .live
        default: return nil
        }
    }

    private static func parseDelay(_ value: String) -> TimeInterval? {
        guard let seconds = TimeInterval(value), seconds.isFinite, seconds >= 0 else { return nil }
        return seconds
    }

    private static func parseTheme(_ value: String) -> AppTheme? {
        switch value {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }
}
