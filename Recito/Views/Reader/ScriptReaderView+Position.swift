//
//  ScriptReaderView+Position.swift
//  Recito
//
//  Position math and reflow handling. Offsets are points, which a reflow
//  (fold/unfold, rotation, resize, text-size change) invalidates, so the
//  playback spot is also tracked as a layout-independent ReadingAnchor. When
//  new paragraph frames arrive for a different layout, the anchor is mapped
//  back to an offset in the new layout. This works whichever of onChange and
//  onPreferenceChange SwiftUI delivers first.
//

import SwiftUI

/// Everything that changes where paragraphs land.
struct ScriptLayoutKey: Equatable {
    let size: CGSize
    let horizontalInsets: CGFloat
    let fontSize: CGFloat
    let lineSpacing: CGFloat
    let serif: Bool
    let bold: Bool
}

extension ScriptReaderView {
    /// The playback spot sits at the viewport center (matches current-index).
    static let playbackLine: CGFloat = 0.5
    /// How long a captured anchor waits for current frames before expiring.
    static let anchorSettleDelay: TimeInterval = 0.4

    var layoutKey: ScriptLayoutKey {
        ScriptLayoutKey(
            size: viewport.size,
            horizontalInsets: viewport.insets.leading + viewport.insets.trailing,
            fontSize: settings.readingFontSize,
            lineSpacing: settings.readingLineSpacing,
            serif: settings.typeface.isSerif,
            bold: settings.boldText
        )
    }

    var geometry: ReadingGeometry {
        ReadingGeometry(
            frames: paragraphFrames,
            headingIndices: Set(vm.scriptSections.filter(\.isHeading).map(\.index)),
            viewportHeight: viewportHeight,
            contentHeight: contentHeight
        )
    }

    var readingIndices: [Int] {
        vm.scriptSections.filter { !$0.isHeading }.map(\.index).sorted()
    }

    /// Whether the measured frames belong to the current layout.
    private var framesAreCurrent: Bool { measuredLayout == layoutKey }

    // MARK: - Reflow

    /// The layout key changed: hold the place and stop any preview.
    func captureAnchorForReflow() {
        cancelReturn()
        isPreviewing = false
        // Frames still belong to the layout being left, so they can seed an
        // anchor even before one was ever remembered.
        pendingAnchor = ReflowAnchor.captured(
            pending: pendingAnchor, last: lastAnchor, outgoing: geometry,
            playbackOffset: vm.playbackOffset, readingLine: Self.playbackLine)
        viewportHeight = viewport.size.height
        recomputeMaxOffset()
        applyPendingAnchor()
        if pendingAnchor != nil { scheduleAnchorExpiry() }
    }

    func framesChanged(_ frames: [Int: CGRect]) {
        // The very first measurement is not a reflow: nothing to carry over.
        let reflowed = measuredLayout != nil && !framesAreCurrent
        paragraphFrames = frames
        viewportHeight = viewport.size.height
        measuredLayout = layoutKey
        if reflowed, pendingAnchor == nil { pendingAnchor = lastAnchor }
        if pendingAnchor == nil { rememberAnchor(for: vm.playbackOffset) }
        applyPendingAnchor()
        updateCurrentFromPlayback()
    }

    func contentHeightChanged(_ height: CGFloat) {
        contentHeight = height
        recomputeMaxOffset()
        applyPendingAnchor()
    }

    /// Seed the remembered anchor so a reflow before the first frame pass
    /// still has a place to hold.
    func seedAnchorOnAppear() {
        guard lastAnchor == nil,
              let section = readingIndices.first(where: { $0 >= vm.currentIndex }) ?? readingIndices.first
        else { return }
        lastAnchor = ReadingAnchor(sectionIndex: section, fraction: 0)
    }

    /// Map the captured anchor into the current frames. It is applied once,
    /// on the first pass where frames are current, then dropped, so later
    /// callbacks never roll auto-scroll back to it.
    private func applyPendingAnchor() {
        let step = ReflowAnchor.apply(
            pending: pendingAnchor, framesAreCurrent: framesAreCurrent,
            geometry: geometry, readingLine: Self.playbackLine)
        pendingAnchor = step.pending
        if let remembered = step.remembered { lastAnchor = remembered }
        guard let offset = step.offset else { return }
        anchorClearWork?.cancel()
        anchorClearWork = nil
        vm.maxOffset = geometry.maxOffset
        vm.playbackOffset = offset
        viewOffset = offset
    }

    /// Safety net, armed once per reflow (never per apply): if no frame pass
    /// ever arrives, stop holding the anchor so tracking can resume.
    private func scheduleAnchorExpiry() {
        anchorClearWork?.cancel()
        let work = DispatchWorkItem {
            if let anchor = pendingAnchor { lastAnchor = anchor }
            pendingAnchor = nil
            anchorClearWork = nil
        }
        anchorClearWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.anchorSettleDelay, execute: work)
    }

    /// Track the playback spot as an anchor while frames are valid.
    func rememberAnchor(for offset: CGFloat) {
        guard pendingAnchor == nil, framesAreCurrent,
              let anchor = geometry.anchor(forOffset: offset, readingLine: Self.playbackLine) else { return }
        lastAnchor = anchor
    }

    func recomputeMaxOffset() {
        vm.maxOffset = max(0, contentHeight - viewportHeight)
        guard pendingAnchor == nil else { return }
        vm.playbackOffset = min(vm.playbackOffset, vm.maxOffset)
        if !isPreviewing { viewOffset = vm.playbackOffset }
    }

    // MARK: - Tracking

    /// The highlighted paragraph is the reading paragraph at the playback center.
    func updateCurrentFromPlayback() {
        guard !vm.voiceFollowActive,
              let nearest = geometry.currentIndex(forPlaybackOffset: vm.playbackOffset),
              nearest != vm.currentIndex else { return }
        vm.currentIndex = nearest
    }

    /// Predictive voice-follow: published ~60×/s and already smoothed, so it's
    /// tracked directly. Skipped while previewing so the user can look around.
    func followVoice(_ position: AlignmentPosition?) {
        guard let position, !isPreviewing,
              let offset = geometry.offset(for: ReadingAnchor(sectionIndex: position.sectionIndex,
                                                              fraction: position.fractionInSection))
        else { return }
        // Only republish on a real boundary crossing (avoids 60 Hz publishes).
        if vm.currentIndex != position.sectionIndex {
            vm.currentIndex = position.sectionIndex
        }
        vm.playbackOffset = offset
        viewOffset = offset
    }
}
