//
//  ReaderViewModel.swift
//  Recito
//
//  Shared reading state for both readers: the parsed document, the current
//  cursor, play/pause + auto-scroll, the elapsed clock, and chrome visibility.
//  Phase-2 voice-follow will move the same `currentIndex`, so the views need no
//  changes when it lands.
//

import SwiftUI
import Combine

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
    private var consumedScriptureIndices: Set<Int> = []

    /// The playback position in points — the spoken/highlighted spot. Advances
    /// with auto-scroll and drives pacing. Independent of where the user is
    /// looking (the view can preview-scroll elsewhere without moving this).
    @Published var playbackOffset: CGFloat = 0
    /// Seconds elapsed since the talk started playing.
    @Published var elapsed: TimeInterval = 0

    /// Maximum scrollable offset; set by the reader view from measured geometry.
    var maxOffset: CGFloat = 0

    private var ticker: Timer?
    private var chromeHideWork: DispatchWorkItem?
    private let tick: TimeInterval = 1.0 / 60.0

    init(talk: Talk, speechSource: SpeechSource? = nil) {
        self.talk = talk
        let parsed = talk.parsed
        self.parsed = parsed
        self.mode = talk.preferredMode
        self.timeLimit = talk.timeLimit
        let source = speechSource ?? Self.bestSpeechSource()
        self.speechSource = source
        self.alignmentEngine = ScriptAlignmentEngine(sections: parsed.scriptSections)
        self.voiceAvailable = source.isAvailable
    }

    /// Tier A (SpeechAnalyzer) on iOS 26+, otherwise Tier B (SFSpeechRecognizer).
    private static func bestSpeechSource() -> SpeechSource {
        if #available(iOS 26.0, *) {
            return SpeechAnalyzerSource()
        }
        return SFSpeechSource()
    }

    deinit {
        ticker?.invalidate()
        speechSource.stop()
    }

    /// Talk time limit in seconds (pacing); editable via the Pacing sheet.
    @Published var timeLimit: TimeInterval

    private var clockRunning = false

    var scriptSections: [ScriptSection] { parsed.scriptSections }
    var outlineNodes: [OutlineNode] { parsed.outlineNodes }

    /// Auto-scroll speed multiplier around the time-paced velocity (1.0 = finish
    /// exactly at the time limit). Set from the speed slider.
    var speedMultiplier: CGFloat = 1

    /// Points/second so the whole script scrolls over the time limit, scaled by
    /// the speed multiplier. This is what keeps "play" naturally on pace.
    private var autoScrollVelocity: CGFloat {
        guard timeLimit > 0, maxOffset > 0 else { return 0 }
        return (maxOffset / CGFloat(timeLimit)) * speedMultiplier
    }

    // MARK: - Voice-follow (Phase 2)

    let speechSource: SpeechSource
    let alignmentEngine: AlignmentEngine
    /// Whether voice-follow is usable on this device (capability ladder).
    let voiceAvailable: Bool
    @Published var voiceFollowActive = false
    /// 0–1 live mic level while listening (drives the "listening" indicator).
    @Published var audioLevel: Float = 0
    /// Predicted reading position, published each tick for smooth scrolling.
    @Published var voicePosition: AlignmentPosition? = nil

    // Predictive scrolling: the recognizer lags ~1–2s, so we glide forward at an
    // estimated reading pace and correct from recognition. Gliding continuously
    // also means we pass through every paragraph (no skipping short ones).
    private var recognizedIndex: Double = 0   // last recognized global token
    private var predictedIndex: Double = 0    // smoothly-advancing read position
    private var lastRecognizedAdvance: TimeInterval = 0
    private var prevRecognizedIndex: Double = 0
    private var prevRecognizedTime: TimeInterval = 0
    /// Reading speed (words/sec), estimated live from recognition. ~2.6 ≈ 155 wpm.
    var wordsPerSecond: Double = 2.6
    /// Max words the prediction may lead the recognizer by.
    var maxLeadWords: Double = 18
    /// If the recognizer hasn't advanced for this long, freeze the glide (pause).
    private let pauseHold: TimeInterval = 1.2

    // Diagnostics (shown in the voice debug panel during bring-up).
    @Published var voiceStatus: String = ""
    @Published var recognizedText: String = ""

    @MainActor
    func toggleVoiceFollow(localeIdentifier: String) async {
        if voiceFollowActive { stopVoiceFollow() } else { await startVoiceFollow(localeIdentifier: localeIdentifier) }
    }

    @MainActor
    func startVoiceFollow(localeIdentifier: String) async {
        guard voiceAvailable, mode == .script else {
            voiceStatus = "Voice-follow needs script mode on a supported device."
            return
        }
        voiceStatus = "Requesting permission…"
        guard await speechSource.requestAuthorization() else {
            voiceStatus = "Microphone or speech permission denied. Enable it in Settings."
            return
        }
        isPlaying = false                 // voice drives position, not time-scroll
        alignmentEngine.reset(to: currentIndex)
        let startIndex = Double(max(alignmentEngine.currentGlobalIndex, 0))
        recognizedIndex = startIndex
        predictedIndex = startIndex
        prevRecognizedIndex = startIndex
        prevRecognizedTime = elapsed
        lastRecognizedAdvance = elapsed
        startClock()                      // keep pacing running + drive the glide
        voiceFollowActive = true
        recognizedText = ""
        voiceStatus = "Starting…"
        wakeChrome()
        do {
            try await speechSource.start(
                localeIdentifier: localeIdentifier,
                onWord: { [weak self] word in
                    guard let self else { return }
                    self.appendRecognized(word.text)
                    if let position = self.alignmentEngine.consume(word) {
                        // Update the recognition anchor; the ticker glides toward it.
                        self.recognizedIndex = Double(position.globalIndex)
                        self.lastRecognizedAdvance = self.elapsed
                        self.estimateReadingPace()
                        if self.predictedIndex < self.recognizedIndex {
                            self.predictedIndex = self.recognizedIndex // never fall behind
                        }
                    }
                },
                onLevel: { [weak self] level in
                    self?.audioLevel = level
                },
                onStatus: { [weak self] status in
                    self?.voiceStatus = status
                },
                onError: { [weak self] message in
                    self?.voiceStatus = "Error: \(message)"
                }
            )
        } catch {
            voiceFollowActive = false
            voiceStatus = "Couldn't start: \(error.localizedDescription)"
            speechSource.stop()
        }
    }

    private func appendRecognized(_ word: String) {
        var words = recognizedText.split(separator: " ").map(String.init)
        words.append(word)
        recognizedText = words.suffix(12).joined(separator: " ")
    }

    func stopVoiceFollow() {
        speechSource.stop()
        voiceFollowActive = false
        audioLevel = 0
        voiceStatus = ""
        voicePosition = nil
    }

    /// Manually re-anchor voice tracking to a section (e.g. double-tap when the
    /// recognizer fell behind) — stays in voice-follow, does not auto-scroll.
    func reseatVoice(to section: Int) {
        alignmentEngine.reset(to: section)
        let idx = Double(max(alignmentEngine.currentGlobalIndex, 0))
        recognizedIndex = idx
        predictedIndex = idx
        prevRecognizedIndex = idx
        prevRecognizedTime = elapsed
        lastRecognizedAdvance = elapsed
        currentIndex = section
    }

    /// The id of the linked citation we're approaching (within ~1 unit), or nil —
    /// used by the auto-open-scripture setting.
    var approachingLinkedCitationID: String? {
        cueShouldExpand ? upcomingCitation?.id : nil
    }

    // MARK: - Pacing

    /// 0...1 fraction of the script consumed (scroll position in script mode,
    /// point position in outline mode).
    var youFill: Double {
        switch mode {
        case .script: return maxOffset > 0 ? Double(playbackOffset / maxOffset) : 0
        case .outline: return pointProgress
        }
    }

    var pace: PaceState {
        PaceState.make(youFill: youFill, elapsed: elapsed, timeLimit: timeLimit)
    }

    /// The next scripture citation at or after the current position, for the cue.
    var upcomingCitation: ScriptureCitation? {
        upcomingLinked()?.citation
    }

    /// The next read-aloud citation and the section/point index where it appears.
    private func upcomingLinked() -> (citation: ScriptureCitation, index: Int)? {
        switch mode {
        case .script:
            let linked = parsed.allCitations.filter { $0.citation.isLinked }
            if let next = linked.first(where: { $0.sectionIndex >= currentIndex }) {
                return (next.citation, next.sectionIndex)
            }
            return linked.first.map { ($0.citation, $0.sectionIndex) }
        case .outline:
            let linked = outlineNodes.flatMap { node in
                node.citations.filter(\.isLinked).map { (citation: $0, index: node.index) }
            }
            if let next = linked.first(where: { $0.index >= currentIndex }) { return next }
            return linked.first
        }
    }

    /// Expand the cue as we approach the scripture — within one paragraph/point.
    var cueShouldExpand: Bool {
        guard let up = upcomingLinked() else { return false }
        return up.index >= currentIndex && (up.index - currentIndex) <= 1
    }

    // MARK: - Playback

    func togglePlay() { isPlaying ? pause() : play() }

    func play() {
        if voiceFollowActive { stopVoiceFollow() } // play and voice are exclusive
        isHoldingForScripture = false
        isPlaying = true
        startClock()
        scheduleChromeHide()
    }

    func pause() {
        isHoldingForScripture = false
        isPlaying = false
        stopClock()
    }

    /// Stop auto-scroll but keep the pacing clock running — used when we reach a
    /// scripture to read. Total elapsed time keeps counting; only the scroll
    /// holds until the speaker resumes.
    private func softPauseForScripture() {
        isPlaying = false
        isHoldingForScripture = true
        wakeChrome() // surface the cue + play control during the read
    }

    /// When the highlight lands on a read-aloud scripture, hold the scroll once.
    private func autoPauseForScriptureIfNeeded() {
        guard mode == .script, isPlaying else { return }
        guard currentIndex >= 0, currentIndex < scriptSections.count else { return }
        guard scriptSections[currentIndex].citations.contains(where: { $0.isLinked }) else { return }
        guard !consumedScriptureIndices.contains(currentIndex) else { return }
        consumedScriptureIndices.insert(currentIndex)
        softPauseForScripture()
    }

    /// Start the pacing clock without auto-scroll (used by the outline reader,
    /// which has no play button).
    func startClock() {
        guard !clockRunning else { return }
        clockRunning = true
        startTicker()
    }

    private func startTicker() {
        stopTicker()
        let timer = Timer(timeInterval: tick, repeats: true) { [weak self] _ in
            guard let self, self.clockRunning else { return }
            self.elapsed += self.tick
            if self.mode == .script, self.isPlaying {
                let next = self.playbackOffset + self.autoScrollVelocity * CGFloat(self.tick)
                self.playbackOffset = min(next, self.maxOffset)
                if self.maxOffset > 0, self.playbackOffset >= self.maxOffset {
                    self.pause()
                }
            }
            if self.voiceFollowActive {
                self.advancePrediction()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        ticker = timer
    }

    /// Glide the predicted reading position forward at reading pace, bounded by
    /// the recognizer, and publish it for the view to scroll to.
    /// Smooth the glide speed toward the speaker's actual measured pace.
    private func estimateReadingPace() {
        let deltaWords = recognizedIndex - prevRecognizedIndex
        let deltaTime = elapsed - prevRecognizedTime
        guard deltaTime >= 0.3, deltaWords >= 1 else { return }
        let instantaneous = deltaWords / deltaTime
        wordsPerSecond = min(max(0.7 * wordsPerSecond + 0.3 * instantaneous, 1.2), 6.0)
        prevRecognizedIndex = recognizedIndex
        prevRecognizedTime = elapsed
    }

    private func advancePrediction() {
        let stalled = elapsed - lastRecognizedAdvance > pauseHold
        if !stalled {
            predictedIndex += wordsPerSecond * tick
        }
        // Stay ahead of recognition, but not by more than the max lead.
        predictedIndex = min(predictedIndex, recognizedIndex + maxLeadWords)
        predictedIndex = max(predictedIndex, recognizedIndex)
        voicePosition = alignmentEngine.position(forFractionalGlobalIndex: predictedIndex)
    }

    private func stopClock() {
        clockRunning = false
        stopTicker()
    }

    private func stopTicker() {
        ticker?.invalidate()
        ticker = nil
    }

    // MARK: - Navigation

    var unitCount: Int {
        mode == .script ? scriptSections.count : outlineNodes.count
    }

    func goToPrevious() {
        guard currentIndex > 0 else { return }
        currentIndex -= 1
    }

    func goToNext() {
        guard currentIndex < unitCount - 1 else { return }
        currentIndex += 1
    }

    /// Flip between Script and Outline, keeping the cursor in range.
    func switchMode() {
        pause()
        mode = (mode == .script) ? .outline : .script
        currentIndex = min(currentIndex, max(0, unitCount - 1))
        playbackOffset = 0
    }

    /// 0...1 progress through the document (for the outline margin rail).
    var pointProgress: Double {
        guard unitCount > 1 else { return 0 }
        return Double(currentIndex) / Double(unitCount - 1)
    }

    // MARK: - Chrome auto-hide

    /// Reveal chrome and (if playing) schedule it to fade again.
    func wakeChrome() {
        chromeVisible = true
        scheduleChromeHide()
    }

    func toggleChrome() {
        if chromeVisible {
            cancelChromeHide()
            chromeVisible = false
        } else {
            wakeChrome()
        }
    }

    private func scheduleChromeHide() {
        cancelChromeHide()
        guard isPlaying else { return }
        let work = DispatchWorkItem { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) { self?.chromeVisible = false }
        }
        chromeHideWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5, execute: work)
    }

    private func cancelChromeHide() {
        chromeHideWork?.cancel()
        chromeHideWork = nil
    }
}
