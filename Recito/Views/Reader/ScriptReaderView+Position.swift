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
    /// How long a captured anchor keeps re-applying to late layout passes.
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
        if pendingAnchor == nil { pendingAnchor = lastAnchor }
        viewportHeight = viewport.size.height
        recomputeMaxOffset()
        applyPendingAnchor()
    }

    func framesChanged(_ frames: [Int: CGRect]) {
        let reflowed = !framesAreCurrent
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

    /// Map the captured anchor into the current frames.
    private func applyPendingAnchor() {
        guard let anchor = pendingAnchor else { return }
        scheduleAnchorClear()
        guard framesAreCurrent,
              let offset = geometry.offset(for: anchor, readingLine: Self.playbackLine) else { return }
        vm.maxOffset = geometry.maxOffset
        vm.playbackOffset = offset
        viewOffset = offset
    }

    private func scheduleAnchorClear() {
        anchorClearWork?.cancel()
        let work = DispatchWorkItem {
            if let anchor = pendingAnchor { lastAnchor = anchor }
            pendingAnchor = nil
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
