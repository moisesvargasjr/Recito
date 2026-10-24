//
//  ReaderViewModel+Verse.swift
//  Recito
//
//  The in-app verse pane. Opening a citation applies a scripture hold: the
//  pacing clock keeps running, auto-scroll holds, and voice-follow keeps
//  listening. Closing leaves the reading position alone and offers Resume;
//  resuming restarts auto-scroll only if it was running before the verse.
//

import Foundation

/// Immutable snapshot of the verse pane's state. Replaced wholesale on every
/// transition so the view sees one consistent change.
struct VerseState: Equatable {
    /// The citation shown in the pane, or nil when the pane is closed.
    let citation: ScriptureCitation?
    /// True after the pane closes until the speaker resumes or plays again.
    let showsResume: Bool
    /// Whether auto-scroll was running (or held for this scripture) when the
    /// verse opened, so Resume knows whether to restart it.
    let resumeAutoScroll: Bool

    static let idle = VerseState(citation: nil, showsResume: false, resumeAutoScroll: false)
}

extension ReaderViewModel {
    /// The citation currently presented in the verse pane.
    var presentedCitation: ScriptureCitation? { verseState.citation }

    /// Whether to show the Resume pill after the pane closed.
    var showsResume: Bool { verseState.showsResume }

    /// Present `citation` in the pane and hold the scroll (clock keeps running).
    func openVerse(_ citation: ScriptureCitation) {
        let wasRunning = isPlaying || isHoldingForScripture || verseState.resumeAutoScroll
        if isPlaying {
            isPlaying = false
            isHoldingForScripture = true
        }
        verseState = VerseState(citation: citation, showsResume: false, resumeAutoScroll: wasRunning)
        wakeChrome()
    }

    /// Dismiss the pane without moving the position; surface Resume.
    func closeVerse() {
        guard verseState.citation != nil else { return }
        verseState = VerseState(
            citation: nil,
            showsResume: true,
            resumeAutoScroll: verseState.resumeAutoScroll
        )
    }

    /// Close the pane (if open) and restart auto-scroll if it was running.
    func resumeAfterVerse() {
        let shouldPlay = verseState.resumeAutoScroll && mode == .script && !voiceFollowActive
        verseState = .idle
        if shouldPlay {
            play()
        } else {
            wakeChrome()
        }
    }

    /// Hide the Resume pill without changing playback (e.g. the speaker
    /// pressed play themselves).
    func dismissResume() {
        guard verseState.showsResume else { return }
        verseState = .idle
    }
}
