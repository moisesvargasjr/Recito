//
//  ScriptReaderView+Gestures.swift
//  Recito
//
//  Drag = preview, double-tap = move playback here, single tap = toggle the
//  bars, plus the Prev/Next transport jumps.
//

import SwiftUI

extension ScriptReaderView {
    // MARK: - Gestures

    /// Double-tap jumps playback to a paragraph; single tap toggles the bars.
    var tapGestures: some Gesture {
        SpatialTapGesture(count: 2)
            .onEnded { jumpToParagraph(nearViewportY: $0.location.y) }
            .exclusively(before: TapGesture(count: 1).onEnded {
                withAnimation(.easeInOut(duration: 0.25)) { vm.toggleChrome() }
            })
    }

    /// Drag = preview only. It moves the view, never the playback point, so the
    /// highlight and pacing keep advancing underneath. After `returnDelay` of no
    /// input, the view animates back to the live playback spot.
    var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                isPreviewing = true
                cancelReturn()
                let start = dragStartOffset ?? viewOffset
                if dragStartOffset == nil { dragStartOffset = start }
                viewOffset = min(max(start - value.translation.height, 0), vm.maxOffset)
                withAnimation(.easeInOut(duration: 0.25)) { vm.wakeChrome() }
            }
            .onEnded { _ in
                dragStartOffset = nil
                scheduleReturn()
            }
    }

    private func scheduleReturn() {
        cancelReturn()
        let work = DispatchWorkItem { returnToLive(duration: 0.45) }
        returnWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + returnDelay, execute: work)
    }

    /// Cancels both the pending return and the delayed end of the preview, so
    /// a late `isPreviewing = false` can't land on a new drag or jump.
    func cancelReturn() {
        returnWork?.cancel()
        returnWork = nil
        previewEndWork?.cancel()
        previewEndWork = nil
    }

    /// Animate the view back to the playback spot and end the preview.
    func returnToLive() { returnToLive(duration: 0.35) }

    private func returnToLive(duration: TimeInterval) {
        cancelReturn()
        withAnimation(.easeInOut(duration: duration)) { viewOffset = vm.playbackOffset }
        let end = DispatchWorkItem {
            isPreviewing = false
            previewEndWork = nil
        }
        previewEndWork = end
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: end)
    }

    // MARK: - Jumps

    /// Prev / Next. While listening they re-anchor the voice tracker to the
    /// neighbouring paragraph; otherwise they move the playback point.
    func transportJump(_ delta: Int) {
        guard let target = neighbouringReading(delta) else { return }
        if vm.voiceFollowActive {
            vm.reseatVoice(to: target)
        } else {
            movePlayback(to: target)
        }
        withAnimation(.easeInOut(duration: 0.25)) { vm.wakeChrome() }
    }

    /// The reading paragraph `delta` steps from the current one (headings skipped).
    private func neighbouringReading(_ delta: Int) -> Int? {
        let reading = readingIndices
        guard !reading.isEmpty else { return nil }
        let position = reading.firstIndex(of: vm.currentIndex)
            ?? reading.enumerated().min(by: {
                abs($0.element - vm.currentIndex) < abs($1.element - vm.currentIndex)
            })?.offset
            ?? 0
        return reading[min(max(position + delta, 0), reading.count - 1)]
    }

    /// Double-tap a paragraph → playback resumes from there. The pacing clock
    /// is untouched, so the pace bar re-reads against the new position.
    private func jumpToParagraph(nearViewportY viewportY: CGFloat) {
        guard let nearest = geometry.nearestReading(toContentY: viewportY + viewOffset) else { return }
        if vm.voiceFollowActive {
            vm.reseatVoice(to: nearest)
            if let offset = geometry.centerOffset(forParagraph: nearest) {
                vm.playbackOffset = offset
                viewOffset = offset
            }
        } else {
            movePlayback(to: nearest)
            vm.play()
        }
    }

    private func movePlayback(to index: Int) {
        cancelReturn()
        isPreviewing = false
        if let offset = geometry.centerOffset(forParagraph: index) {
            vm.playbackOffset = offset
            viewOffset = offset
        }
        vm.currentIndex = index
    }
}
