//
//  ScriptReaderView.swift
//  Recito
//
//  Prose teleprompter. Two decoupled positions:
//   • playback (vm.playbackOffset) — the highlighted/spoken spot; advances with
//     auto-scroll and drives pacing. Never moved by previewing.
//   • view (viewOffset) — where the reader is looking. Normally tracks playback;
//     a drag detaches it for a preview, and after a few seconds of no input it
//     animates back to playback.
//  Fold, rotation, resize and text-size changes keep the place: the playback
//  spot is captured as a ReadingAnchor before reflow and re-derived from the
//  new paragraph frames (see +Position). Gestures live in +Gestures.
//  The reader fills its region edge to edge; stable safe-area insets pad the
//  column and overlays, so hiding the bars never reflows text.
//

import SwiftUI

struct ScriptReaderView: View {
    @EnvironmentObject var settings: DisplaySettings
    @ObservedObject var vm: ReaderViewModel
    let viewport: ReaderViewport
    /// Latest transport request from the toolbar / transport panel.
    let command: ReaderCommand?
    /// False in tabletop (the transport panel shows pace and cue).
    let showsPaceAndCue: Bool
    let onOpenScripture: (ScriptureCitation) -> Void

    // Internal (not private) so the +Position / +Gestures extensions can reach them.
    @State var paragraphFrames: [Int: CGRect] = [:]
    @State var contentHeight: CGFloat = 0
    @State var viewportHeight: CGFloat = 0
    @State var viewOffset: CGFloat = 0
    @State var isPreviewing = false
    @State var dragStartOffset: CGFloat?
    @State var returnWork: DispatchWorkItem?
    /// Playback position captured before a reflow, re-applied to new frames.
    @State var pendingAnchor: ReadingAnchor?
    @State var anchorClearWork: DispatchWorkItem?
    /// Last playback anchor measured against frames of the current layout.
    @State var lastAnchor: ReadingAnchor?
    /// The layout the current `paragraphFrames` were measured in.
    @State var measuredLayout: ScriptLayoutKey?

    /// Seconds of no input before the view snaps back to the playback spot.
    let returnDelay: TimeInterval = 3.0

    var body: some View {
        ZStack {
            Theme.bg
            column
            ReaderOverlays(vm: vm, insets: viewport.insets,
                           showsPaceAndCue: showsPaceAndCue,
                           onOpenScripture: onOpenScripture)
            topNotices
            #if DEBUG
            if vm.voiceFollowActive && settings.showVoiceDebug {
                VStack { Spacer(); VoiceDebugPanel(vm: vm) }
                    .padding(.bottom, viewport.insets.bottom + Spacing.xxxl + Spacing.xxl)
            }
            #endif
        }
        .frame(width: viewport.size.width, height: viewport.size.height)
        .onAppear(perform: handleAppear)
        .onChange(of: layoutKey) { _ in captureAnchorForReflow() }
        .onChange(of: vm.playbackOffset) { newValue in
            updateCurrentFromPlayback()
            rememberAnchor(for: newValue)
            if !isPreviewing && !vm.voiceFollowActive { viewOffset = newValue }
        }
        .onChange(of: settings.autoScrollSpeed) { _ in
            vm.speedMultiplier = settings.autoScrollMultiplier
        }
        .onChange(of: vm.voicePosition) { followVoice($0) }
        .onChange(of: command) { handle($0) }
    }

    // MARK: - Column

    private var column: some View {
        let insets = viewport.insets
        let available = max(0, viewport.size.width - insets.leading - insets.trailing)
        let layout = LayoutMetrics.readableColumn(containerWidth: available,
                                                  fontSize: settings.readingFontSize)
        return ScriptReadingColumn(
            sections: vm.scriptSections,
            currentIndex: vm.currentIndex,
            font: settings.readingFont(),
            lineSpacing: settings.readingLineSpacing,
            leadingPadding: insets.leading + layout.sidePadding,
            trailingPadding: insets.trailing + layout.sidePadding,
            verticalPadding: viewport.size.height * 0.4,
            viewOffset: viewOffset,
            onFrames: framesChanged,
            onContentHeight: contentHeightChanged
        )
        .frame(width: viewport.size.width, height: viewport.size.height, alignment: .top)
        .clipped()
        .contentShape(Rectangle())
        .gesture(dragGesture)
        .gesture(tapGestures)
    }

    /// Voice status and "Back to current", stacked under the pace bar.
    private var topNotices: some View {
        VStack(spacing: Spacing.sm) {
            if showsVoiceStatus { VoiceStatusPill(text: vm.voiceStatus) }
            if isPreviewing { BackToCurrentButton(action: returnToLive) }
            Spacer(minLength: 0)
        }
        .padding(.top, viewport.insets.top + Spacing.lg)
        .padding(.horizontal, Spacing.lg)
    }

    /// Only status that needs attention (model download / errors) — the
    /// listening indicator already covers the normal active state.
    private var showsVoiceStatus: Bool {
        !vm.voiceStatus.isEmpty && !vm.voiceStatus.hasPrefix("Listening")
    }

    // MARK: - Lifecycle

    private func handleAppear() {
        viewportHeight = viewport.size.height
        viewOffset = vm.playbackOffset
        vm.speedMultiplier = settings.autoScrollMultiplier
    }

    private func handle(_ command: ReaderCommand?) {
        guard let command else { return }
        switch command.kind {
        case .jump(let delta): transportJump(delta)
        }
    }
}
