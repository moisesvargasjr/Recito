//
//  LaunchConfigurationTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

struct LaunchConfigurationTests {
    private func parse(_ args: [String], env: [String: String] = [:]) -> LaunchConfiguration {
        LaunchConfiguration.parse(arguments: ["Recito"] + args, environment: env)
    }

    @Test func plainLaunchIsProductionBehaviour() {
        let c = parse([])
        #expect(!c.isUITest)
        #expect(!c.resetState)
        #expect(c.fixture == nil)
        #expect(c.speech == .live)
        #expect(c.chromeHideDelay == 3.5)
        #expect(!c.disableAnimations)
        #expect(c.theme == nil)
        #expect(c.openTalkID == nil)
        #expect(c.fakeSpeechWords.isEmpty)
    }

    @Test func uiTestDefaultsSpeechToFake() {
        #expect(parse(["-uitest"]).speech == .fake)
    }

    @Test func explicitSpeechOverridesTheDefault() {
        #expect(parse(["-uitest", "-speech", "unavailable"]).speech == .unavailable)
        #expect(parse(["-uitest", "-speech", "live"]).speech == .live)
        #expect(parse(["-speech", "fake"]).speech == .fake)
    }

    @Test func invalidSpeechFallsBackToTheDefault() {
        #expect(parse(["-uitest", "-speech", "bogus"]).speech == .fake)
        #expect(parse(["-speech", "bogus"]).speech == .live)
        #expect(parse(["-uitest", "-speech"]).speech == .fake)
    }

    @Test func flagsAreRecognised() {
        let c = parse(["-uitest", "-reset", "-noAnimations"])
        #expect(c.isUITest)
        #expect(c.resetState)
        #expect(c.disableAnimations)
    }

    @Test(arguments: [
        ("samples", UITestFixture.samples), ("empty", .empty), ("longScript", .longScript),
        ("outline", .outline), ("many", .many), ("mixedHidden", .mixedHidden),
    ])
    func seedNamesMapToFixtures(name: String, expected: UITestFixture) {
        #expect(parse(["-uitest", "-seed", name]).fixture == expected)
    }

    @Test func unknownSeedIsNil() {
        #expect(parse(["-uitest", "-seed", "nope"]).fixture == nil)
    }

    @Test func chromeHideDelayParsesValidNumbers() {
        #expect(parse(["-chromeHideDelay", "0.5"]).chromeHideDelay == 0.5)
        #expect(parse(["-chromeHideDelay", "0"]).chromeHideDelay == 0)
    }

    @Test(arguments: ["abc", "-1", "nan", "inf", ""])
    func invalidChromeHideDelayFallsBackToDefault(value: String) {
        #expect(parse(["-chromeHideDelay", value]).chromeHideDelay == 3.5)
    }

    @Test func missingChromeHideDelayValueFallsBackToDefault() {
        #expect(parse(["-chromeHideDelay"]).chromeHideDelay == 3.5)
    }

    @Test func themeOverride() {
        #expect(parse(["-theme", "dark"]).theme == .dark)
        #expect(parse(["-theme", "light"]).theme == .light)
        #expect(parse(["-theme", "sepia"]).theme == nil)
    }

    @Test func openTalkTakesTheNextArgument() {
        #expect(parse(["-openTalk", "abc-123"]).openTalkID == "abc-123")
        #expect(parse(["-openTalk"]).openTalkID == nil)
    }

    @Test func unknownArgumentsAreIgnored() {
        let c = parse(["-NSDoubleLocalizedStrings", "YES", "-uitest", "--weird"])
        #expect(c.isUITest)
        #expect(c.speech == .fake)
    }

    @Test func valueIsNotMistakenForAFlag() {
        // "-reset" here is the *value* of -seed, so it must not enable reset.
        let c = parse(["-seed", "-reset"])
        #expect(!c.resetState)
        #expect(c.fixture == nil)
    }

    @Test func fakeSpeechWordsComeFromTheEnvironment() {
        let c = parse(["-uitest"], env: ["RECITO_FAKE_SPEECH_WORDS": "one two  three"])
        #expect(c.fakeSpeechWords == ["one", "two", "three"])
    }
}
