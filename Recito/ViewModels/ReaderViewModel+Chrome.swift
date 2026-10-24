//
//  ReaderViewModel+Chrome.swift
//  Recito
//
//  Chrome auto-hide. The delay and scheduler come from ReaderDependencies.
//

import SwiftUI
import Combine

extension ReaderViewModel {
    /// Reveal chrome and (if running) schedule it to fade again.
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

    func scheduleChromeHide() {
        cancelChromeHide()
        // Auto-hide whenever the reader is actively running — auto-scroll OR
        // voice-follow (which keeps isPlaying false). Otherwise the bar and its
        // instruction caption would stay up for the whole talk.
        guard isPlaying || voiceFollowActive else { return }
        chromeHideCancellable = deps.scheduler.schedule(after: deps.chromeHideDelay) { [weak self] in
            withAnimation(.easeOut(duration: 0.3)) { self?.chromeVisible = false }
        }
    }

    private func cancelChromeHide() {
        chromeHideCancellable?.cancel()
        chromeHideCancellable = nil
    }
}
