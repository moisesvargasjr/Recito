//
//  ReaderViewModelFollowModeTests.swift
//  RecitoTests
//
//  Auto-scroll vs. voice selection (selecting never starts anything).
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct ReaderViewModelFollowModeTests {
    @Test func labelsAndSymbols() {
        #expect(FollowMode.autoScroll.label == "Auto")
        #expect(FollowMode.voice.label == "Voice")
        #expect(FollowMode.autoScroll.symbol == "arrow.down")
        #expect(FollowMode.voice.symbol == "waveform")
        #expect(FollowMode.voice.rawValue == "voice")
    }

    @Test func startsInAutoScroll() {
        let h = ReaderHarness()
        #expect(h.vm.followMode == .autoScroll)
        #expect(!h.vm.isFollowRunning)
    }

    @Test func selectingVoiceDoesNotStartListening() {
        let h = ReaderHarness()
        h.vm.setFollowMode(.voice)
        #expect(h.vm.followMode == .voice)
        #expect(h.speech.startCount == 0)
        #expect(!h.vm.voiceFollowActive)
    }

    @Test func switchingBackToAutoDoesNotPlay() {
        let h = ReaderHarness()
        h.vm.setFollowMode(.voice)
        h.vm.setFollowMode(.autoScroll)
        #expect(h.vm.followMode == .autoScroll)
        #expect(!h.vm.isPlaying)
    }

    @Test func changingModeWakesTheChrome() {
        let h = ReaderHarness()
        h.vm.chromeVisible = false
        h.vm.setFollowMode(.voice)
        #expect(h.vm.chromeVisible)
    }

    @Test func sameModeDoesNotWakeTheChrome() {
        let h = ReaderHarness()
        h.vm.chromeVisible = false
        h.vm.setFollowMode(.autoScroll)
        #expect(!h.vm.chromeVisible)
    }

    @Test func isFollowRunningTracksAutoScroll() {
        let h = ReaderHarness()
        h.vm.play()
        #expect(h.vm.isFollowRunning)
        h.vm.pause()
        #expect(!h.vm.isFollowRunning)
    }

    @Test func voiceModeIgnoresAutoScrollPlayingFlag() {
        let h = ReaderHarness()
        h.vm.setFollowMode(.voice)
        #expect(!h.vm.isFollowRunning)
    }

    @Test func leavingVoiceWhileListeningPausesIt() async {
        let h = ReaderHarness(talk: TalkFactory.talk(text: TalkFactory.voiceScript))
        h.vm.setFollowMode(.voice)
        await h.vm.startVoiceFollow(localeIdentifier: "en-US")
        #expect(h.vm.voiceFollowActive)
        h.vm.setFollowMode(.autoScroll)
        #expect(!h.vm.voiceFollowActive)
        #expect(!h.vm.isFollowRunning)
    }
}
