//
//  ReaderViewModel+Pacing.swift
//  Recito
//
//  Progress/pace values, the scripture cue, play/pause + auto-scroll, the
//  pacing clock, and navigation.
//

import SwiftUI
import Combine

extension ReaderViewModel {
    // MARK: - Pacing values

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

    /// 0...1 progress through the document (for the outline margin rail).
    var pointProgress: Double {
        guard unitCount > 1 else { return 0 }
        return Double(currentIndex) / Double(unitCount - 1)
    }

    /// Points/second so the whole script scrolls over the time limit, scaled by
    /// the speed multiplier. This is what keeps "play" naturally on pace.
    private var autoScrollVelocity: CGFloat {
        guard timeLimit > 0, maxOffset > 0 else { return 0 }
        return (maxOffset / CGFloat(timeLimit)) * speedMultiplier
    }

    // MARK: - Scripture cue

    /// The next scripture citation at or after the current position, for the cue.
    var upcomingCitation: ScriptureCitation? {
        upcomingLinked()?.citation
    }

    /// The id of the linked citation we're approaching (within ~1 unit), or nil —
    /// used by the auto-open-scripture setting.
    var approachingLinkedCitationID: String? {
        cueShouldExpand ? upcomingCitation?.id : nil
    }

    /// Expand the cue as we approach the scripture — within one paragraph/point.
    var cueShouldExpand: Bool {
        guard let up = upcomingLinked() else { return false }
        return up.index >= currentIndex && (up.index - currentIndex) <= 1
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

    // MARK: - Playback

    func togglePlay() { isPlaying ? pause() : play() }

    /// Is the *active* follow mode currently running — drives the play/pause icon.
    var isFollowRunning: Bool { followMode == .voice ? voiceFollowActive : isPlaying }

    /// Flip Auto-scroll ↔ Voice, stopping whatever was running first. Does not
    /// auto-start the new mode (the play button does that).
    func setFollowMode(_ newMode: FollowMode) {
        guard newMode != followMode else { return }
        if voiceFollowActive { pauseVoice() }
        if isPlaying { pause() }
        followMode = newMode
        wakeChrome()
    }

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
    func autoPauseForScriptureIfNeeded() {
        guard mode == .script, isPlaying else { return }
        guard currentIndex >= 0, currentIndex < scriptSections.count else { return }
        guard scriptSections[currentIndex].citations.contains(where: { $0.isLinked }) else { return }
        guard !consumedScriptureIndices.contains(currentIndex) else { return }
        consumedScriptureIndices.insert(currentIndex)
        softPauseForScripture()
    }

    // MARK: - Clock

    /// Start the pacing clock without auto-scroll (used by the outline reader,
    /// which has no play button).
    func startClock() {
        guard !clockRunning else { return }
        clockRunning = true
        tickCancellable?.cancel()
        tickCancellable = deps.ticker.start(interval: tick) { [weak self] dt in
            self?.handleTick(dt)
        }
    }

    func stopClock() {
        clockRunning = false
        tickCancellable?.cancel()
        tickCancellable = nil
    }

    private func handleTick(_ dt: TimeInterval) {
        guard clockRunning else { return }
        elapsed += dt
        if mode == .script, isPlaying {
            let next = playbackOffset + autoScrollVelocity * CGFloat(dt)
            playbackOffset = min(next, maxOffset)
            if maxOffset > 0, playbackOffset >= maxOffset {
                pause()
            }
        }
        if voiceFollowActive {
            advanceVoiceGlide(dt: dt)
        }
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
        if voiceFollowActive { pauseVoice() }
        pause()
        mode = (mode == .script) ? .outline : .script
        // Voice-follow only exists in script mode; reset so we return cleanly.
        if mode == .outline { followMode = .autoScroll }
        currentIndex = min(currentIndex, max(0, unitCount - 1))
        playbackOffset = 0
    }
}
