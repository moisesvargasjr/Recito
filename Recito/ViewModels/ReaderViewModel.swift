//
//  ReaderViewModel.swift
//  Recito
//
//  Shared reading state for both readers: the parsed document, the current
//  cursor, play/pause + auto-scroll, the elapsed clock, and chrome visibility.
//  Behaviour is split by concern across extensions:
//    +Pacing  - progress, cue, playback, ticker, navigation
//    +Voice   - speech-driven follow and the predictive glide
//    +Chrome  - auto-hide of the reader chrome
//  Stored state lives here because extensions cannot hold it. Time and speech
//  come in through `ReaderDependencies`, so tests drive everything by hand.
//

import SwiftUI
import Combine
import os

/// How the reader advances: time-paced auto-scroll, or speech-driven
/// voice-follow. The play button starts/pauses whichever is active.
enum FollowMode: String {
    case autoScroll
    case voice
    var label: String { self == .voice ? "Voice" : "Auto" }
    var symbol: String { self == .voice ? "waveform" : "arrow.down" }
}

final class ReaderViewModel: ObservableObject {
    let talk: Talk
    let parsed: ParsedDocument

    @Published var mode: DocumentMode
    @Published var currentIndex: Int = 0 {
        didSet { autoPauseForScriptureIfNeeded() }
    }
    @Published var isPlaying = false
    @Published var chromeVisible = true

    /// True when auto-scroll was paused because we reached a read-aloud
    /// scripture (the pace clock keeps running). Cleared on resume.
    @Published var isHoldingForScripture = false

    /// The playback position in points — the spoken/highlighted spot. Advances
    /// with auto-scroll and drives pacing. Independent of where the user is
    /// looking (the view can preview-scroll elsewhere without moving this).
    @Published var playbackOffset: CGFloat = 0
    /// Seconds elapsed since the talk started playing.
    @Published var elapsed: TimeInterval = 0
    /// Talk time limit in seconds (pacing); editable via the Pacing sheet.
    @Published var timeLimit: TimeInterval

    // MARK: Voice-follow state

    @Published var voiceFollowActive = false
    /// Active follow mode. The on-screen switch flips this (only offered when
    /// voice-follow is available — script mode, supported device). Selecting a
    /// mode does NOT start it; the play button does.
    @Published var followMode: FollowMode = .autoScroll
    /// 0–1 live mic level while listening (drives the "listening" indicator).
    @Published var audioLevel: Float = 0
    /// Predicted reading position, published each tick for smooth scrolling.
    @Published var voicePosition: AlignmentPosition?
    // Diagnostics (shown in the voice debug panel during bring-up).
    @Published var voiceStatus: String = ""
    @Published var recognizedText: String = ""
    /// How many words the predicted position is leading the recognizer by — i.e.
    /// how much the predictive scroller is papering over ASR lag.
    @Published var voiceLeadWords: Double = 0
    /// Recognizer's current global token index (advances as words are confirmed).
    @Published var voiceRecognizedIndex: Double = 0

    let speechSource: SpeechSource
    let alignmentEngine: AlignmentEngine
    /// Whether voice-follow is usable on this device (capability ladder).
    let voiceAvailable: Bool

    /// Maximum scrollable offset; set by the reader view from measured geometry.
    var maxOffset: CGFloat = 0
    /// Auto-scroll speed multiplier around the time-paced velocity (1.0 = finish
    /// exactly at the time limit). Set from the speed slider.
    var speedMultiplier: CGFloat = 1

    // Internal (not private) only so the per-concern extensions can reach them.
    let deps: ReaderDependencies
    let tick: TimeInterval = 1.0 / 60.0
    var clockRunning = false
    var tickCancellable: Cancellable?
    var chromeHideCancellable: Cancellable?
    var consumedScriptureIndices: Set<Int> = []
    var predictor = VoicePredictor()
    var thermalObserver: NSObjectProtocol?

    /// Diagnostics for the voice-follow freeze investigation. `os.Logger` is
    /// visible in Console.app / device logs even in TestFlight (release) builds,
    /// so a real talk can confirm whether a stall coincides with thermal
    /// throttling. Filter Console for subsystem `com.moisesvargas.Recito`.
    let voiceLog = Logger(subsystem: "com.moisesvargas.Recito", category: "voice")

    init(talk: Talk, deps: ReaderDependencies = .live) {
        self.talk = talk
        let parsed = talk.parsed
        self.parsed = parsed
        self.deps = deps
        self.mode = talk.preferredMode
        self.timeLimit = talk.timeLimit
        let source = deps.speechSourceFactory()
        self.speechSource = source
        self.alignmentEngine = deps.alignmentFactory(parsed.scriptSections)
        self.voiceAvailable = source.isAvailable
    }

    /// Use a specific speech source with otherwise-live dependencies.
    convenience init(talk: Talk, speechSource: SpeechSource) {
        var deps = ReaderDependencies.live
        deps.speechSourceFactory = { speechSource }
        self.init(talk: talk, deps: deps)
    }

    deinit {
        tickCancellable?.cancel()
        chromeHideCancellable?.cancel()
        speechSource.stop()
        if let thermalObserver {
            NotificationCenter.default.removeObserver(thermalObserver)
        }
    }

    var scriptSections: [ScriptSection] { parsed.scriptSections }
    var outlineNodes: [OutlineNode] { parsed.outlineNodes }
}
