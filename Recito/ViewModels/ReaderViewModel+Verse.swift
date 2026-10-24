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
    /// True while the citation is open in an external app (JW Library); the
    /// reader offers Resume when the app becomes active again.
    var awaitingReturn: Bool = false

    static let idle = VerseState(citation: nil, showsResume: false, resumeAutoScroll: false)
}

/// What the view must do to show a scripture, decided by `openScripture`.
enum ScriptureAction: Equatable {
    /// Open this URL in the reference app (the view performs `openURL`).
    case external(URL)
    /// The verse pane is now presented in-app.
    case pane
    /// No link could be built; nothing changed.
    case unavailable
}

extension ReaderViewModel {
    /// The citation currently presented in the verse pane.
    var presentedCitation: ScriptureCitation? { verseState.citation }

    /// Whether to show the Resume pill after the pane closed.
    var showsResume: Bool { verseState.showsResume }

    /// The single place a scripture is opened (cue chip, inline citation, or
    /// the open-as-you-approach setting). Applies the scripture hold either way.
    func openScripture(
        _ citation: ScriptureCitation,
        destination: ScriptureDestination,
        linker: ScriptureLinker = JWLibraryLinker()
    ) -> ScriptureAction {
        switch destination {
        case .inApp:
            openVerse(citation)
            return .pane
        case .jwLibrary:
            guard let url = citation.url ?? linker.url(for: citation) else { return .unavailable }
            let wasRunning = holdForScripture()
            verseState = VerseState(citation: nil, showsResume: false,
                                    resumeAutoScroll: wasRunning, awaitingReturn: true)
            return .external(url)
        }
    }

    /// Present `citation` in the pane and hold the scroll (clock keeps running).
    func openVerse(_ citation: ScriptureCitation) {
        let wasRunning = holdForScripture()
        verseState = VerseState(citation: citation, showsResume: false, resumeAutoScroll: wasRunning)
        wakeChrome()
    }

    /// The app became active again after an external scripture: stay put and
    /// offer Resume if auto-scroll was running.
    func returnedFromExternalScripture() {
        guard verseState.awaitingReturn else { return }
        verseState = verseState.resumeAutoScroll
            ? VerseState(citation: nil, showsResume: true, resumeAutoScroll: true)
            : .idle
    }

    /// Hold auto-scroll (clock keeps running). Returns whether auto-scroll was
    /// running, already held, or already pending resume.
    private func holdForScripture() -> Bool {
        let wasRunning = isPlaying || isHoldingForScripture || verseState.resumeAutoScroll
        if isPlaying {
            isPlaying = false
            isHoldingForScripture = true
        }
        return wasRunning
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
