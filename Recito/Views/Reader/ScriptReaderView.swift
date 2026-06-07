//
//  ScriptReaderView.swift
//  Recito
//
//  Prose teleprompter. Two decoupled positions:
//   • playback (vm.playbackOffset) — the highlighted/spoken spot; advances with
//     auto-scroll and drives pacing. Never moved by previewing.
//   • view (viewOffset) — where the reader is looking. Normally tracks playback
//     to keep the current paragraph centered; a drag detaches it for a preview,
//     and after a few seconds of no input it animates back to playback.
//  Double-tap moves the playback point to the tapped paragraph and resumes.
//

import SwiftUI
import UIKit

struct ScriptReaderView: View {
    @EnvironmentObject private var settings: DisplaySettings
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var vm: ReaderViewModel

    /// Each reading section's frame in content space (for word-level scrolling).
    @State private var paragraphFrames: [Int: CGRect] = [:]
    @State private var contentHeight: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0

    /// Where the content is currently shown (may differ from playback while
    /// previewing).
    @State private var viewOffset: CGFloat = 0
    @State private var isPreviewing = false
    @State private var dragStartOffset: CGFloat? = nil
    @State private var returnWork: DispatchWorkItem? = nil

    @State private var showSettings = false
    @State private var showPacing = false
    /// Citations already auto-opened this session (avoid reopening).
    @State private var autoOpenedCitations: Set<String> = []

    private let linker: ScriptureLinker = JWLibraryLinker()
    /// Seconds of no input before the view snaps back to the playback spot.
    private let returnDelay: TimeInterval = 3.0

    var body: some View {
        GeometryReader { geo in
            let viewportH = geo.size.height
            let sidePadding = Self.sidePadding(for: geo.size.width)

            ZStack {
                Theme.bg.ignoresSafeArea()

                readingColumn(viewportH: viewportH, sidePadding: sidePadding)
                    .frame(width: geo.size.width, height: viewportH, alignment: .top)
                    .clipped()
                    .contentShape(Rectangle())
                    .gesture(dragGesture)
                    .gesture(
                        SpatialTapGesture(count: 2)
                            .onEnded { jumpToParagraph(nearViewportY: $0.location.y) }
                            .exclusively(before: TapGesture(count: 1).onEnded { vm.toggleChrome() })
                    )

                VStack(spacing: 0) {
                    PaceBarView(pace: vm.pace)
                    Spacer(minLength: 0)
                }

                if showsVoiceStatus {
                    VStack { voiceStatusPill; Spacer() }.padding(.top, 92)
                }

                if isPreviewing {
                    returnToLiveButton
                }

                ReaderChrome(
                    vm: vm,
                    labeledPrevNext: false,
                    onClose: { dismiss() },
                    onAa: { showSettings = true },
                    onPrev: { jump(by: -1) },
                    onNext: { jump(by: 1) },
                    onSizeDown: { adjustTextSize(-0.08) },
                    onSizeUp: { adjustTextSize(0.08) },
                    onPaceTap: { showPacing = true },
                    voiceAvailable: vm.voiceAvailable,
                    voiceActive: vm.voiceFollowActive,
                    onToggleVoice: {
                        Task { await vm.toggleVoiceFollow(localeIdentifier: settings.recognitionLanguage) }
                    },
                    topTrailing: cueChip
                )
            }
            .onAppear {
                viewportHeight = viewportH
                viewOffset = vm.playbackOffset
                vm.speedMultiplier = settings.autoScrollMultiplier
            }
            .onChange(of: viewportH) { newValue in
                viewportHeight = newValue
                recomputeMaxOffset()
            }
            // Time-paced playback advances independently; keep the highlight
            // current and (if not previewing) keep the view tracking it. During
            // voice-follow the view is driven by the voice handler below instead.
            .onChange(of: vm.playbackOffset) { newValue in
                updateCurrentFromPlayback()
                if !isPreviewing && !vm.voiceFollowActive { viewOffset = newValue }
            }
            .onChange(of: settings.autoScrollSpeed) { _ in
                vm.speedMultiplier = settings.autoScrollMultiplier
            }
            // Auto-open the reference app at a scripture as we approach it (opt-in).
            .onChange(of: vm.approachingLinkedCitationID) { id in
                guard settings.autoOpenScripture,
                      let id, !autoOpenedCitations.contains(id),
                      let citation = vm.upcomingCitation,
                      let url = citation.url ?? linker.url(for: citation) else { return }
                autoOpenedCitations.insert(id)
                UIApplication.shared.open(url)
            }
            // Predictive voice-follow: the position is published ~60×/s and
            // glides smoothly, so we track it directly (no per-update animation).
            // Skipped while previewing so the user can look around freely.
            .onChange(of: vm.voicePosition) { position in
                guard let position, !isPreviewing,
                      let offset = wordOffset(section: position.sectionIndex,
                                              fraction: position.fractionInSection) else { return }
                vm.currentIndex = position.sectionIndex
                vm.playbackOffset = offset
                viewOffset = offset
            }
        }
        .keepAwake(settings.keepAwake)
        .sheet(isPresented: $showSettings) { TextDisplaySheet() }
        .sheet(isPresented: $showPacing) { PacingSheet(timeLimit: $vm.timeLimit) }
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Reading column

    private func readingColumn(viewportH: CGFloat, sidePadding: CGFloat) -> some View {
        let verticalPad = viewportH * 0.4

        return VStack(alignment: .leading, spacing: 22) {
            ForEach(vm.scriptSections) { section in
                paragraphView(section)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ParagraphFrameKey.self,
                                value: [section.index: proxy.frame(in: .named(ReaderSpace.name))]
                            )
                        }
                    )
            }
        }
        .padding(.horizontal, sidePadding)
        .padding(.vertical, verticalPad)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
            }
        )
        // Name the content's own coordinate space, then offset it. Paragraph
        // positions measured in this space are independent of scrolling, so the
        // preference fires only on real layout changes — not 60×/sec.
        .coordinateSpace(name: ReaderSpace.name)
        .offset(y: -viewOffset)
        .onPreferenceChange(ParagraphFrameKey.self) { values in
            paragraphFrames = values
            updateCurrentFromPlayback()
        }
        .onPreferenceChange(ContentHeightKey.self) { height in
            contentHeight = height
            recomputeMaxOffset()
        }
    }

    @ViewBuilder
    private func paragraphView(_ section: ScriptSection) -> some View {
        if section.isHeading {
            headingView(section)
        } else {
            proseView(section)
        }
    }

    /// A section label the speaker doesn't read — a quiet divider for orientation.
    private func headingView(_ section: ScriptSection) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Rectangle().fill(Theme.separator).frame(height: 1)
            Text(section.text.uppercased())
                .font(.system(size: 14, weight: .semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.ink3)
        }
        .padding(.leading, Spacing.xl)
        .padding(.top, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func proseView(_ section: ScriptSection) -> some View {
        let state = paragraphState(section.index)
        return Text(section.text)
            .font(settings.readingFont())
            .lineSpacing(settings.readingLineSpacing)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(state.color)
            .opacity(state.opacity)
            // Constant gutter for ALL paragraphs so switching the current one
            // never changes text width/height — otherwise the height shift feeds
            // back into current-paragraph detection and loops forever.
            .padding(.leading, Spacing.xl)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.accent)
                    .frame(width: 4)
                    .opacity(state == .current ? 1 : 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Paragraph state

    private enum ParagraphState {
        case past, current, upcoming
        var color: Color {
            switch self {
            case .past: return Theme.ink3
            case .current: return Theme.ink
            case .upcoming: return Theme.ink2
            }
        }
        var opacity: Double { self == .upcoming ? 0.6 : 1 }
    }

    private func paragraphState(_ index: Int) -> ParagraphState {
        if index < vm.currentIndex { return .past }
        if index == vm.currentIndex { return .current }
        return .upcoming
    }

    // MARK: - Position math

    /// Paragraph positions excluding headings (headings aren't read, so the
    /// highlight and jumps never land on them).
    private var readingMidYs: [Int: CGFloat] {
        let headingIndices = Set(vm.scriptSections.filter(\.isHeading).map(\.index))
        return paragraphFrames
            .filter { !headingIndices.contains($0.key) }
            .mapValues { $0.midY }
    }

    private var readingIndices: [Int] {
        vm.scriptSections.filter { !$0.isHeading }.map(\.index).sorted()
    }

    /// The highlighted paragraph is the reading paragraph at the playback center.
    private func updateCurrentFromPlayback() {
        guard !vm.voiceFollowActive else { return } // voice sets the highlight itself
        let center = vm.playbackOffset + viewportHeight / 2
        guard let nearest = readingMidYs.min(by: {
            abs($0.value - center) < abs($1.value - center)
        }) else { return }
        if nearest.key != vm.currentIndex {
            vm.currentIndex = nearest.key
        }
    }

    private func recomputeMaxOffset() {
        vm.maxOffset = max(0, contentHeight - viewportHeight)
        vm.playbackOffset = min(vm.playbackOffset, vm.maxOffset)
        if !isPreviewing { viewOffset = vm.playbackOffset }
    }

    /// Content offset that centers a paragraph.
    private func centerOffset(forParagraph index: Int) -> CGFloat? {
        guard let frame = paragraphFrames[index] else { return nil }
        return min(max(frame.midY - viewportHeight / 2, 0), vm.maxOffset)
    }

    /// Content offset that places a fractional point within a paragraph at a
    /// comfortable reading line (~42% down the viewport).
    private func wordOffset(section: Int, fraction: Double) -> CGFloat? {
        guard let frame = paragraphFrames[section] else { return nil }
        let contentY = frame.minY + CGFloat(fraction) * frame.height
        return min(max(contentY - viewportHeight * 0.42, 0), vm.maxOffset)
    }

    // MARK: - Navigation / interaction

    /// Prev / Next move the playback point to the neighboring reading paragraph
    /// (skipping headings).
    private func jump(by delta: Int) {
        let reading = readingIndices
        guard !reading.isEmpty else { return }
        let currentPos = reading.firstIndex(of: vm.currentIndex)
            ?? reading.enumerated().min(by: {
                abs($0.element - vm.currentIndex) < abs($1.element - vm.currentIndex)
            })?.offset
            ?? 0
        let newPos = min(max(currentPos + delta, 0), reading.count - 1)
        movePlayback(to: reading[newPos])
    }

    /// Double-tap a paragraph → playback resumes from there (nearest reading
    /// paragraph). The pacing clock is untouched, so total elapsed time is
    /// unchanged and the pace bar re-reads against the new position.
    private func jumpToParagraph(nearViewportY viewportY: CGFloat) {
        let contentY = viewportY + viewOffset
        guard let nearest = readingMidYs.min(by: {
            abs($0.value - contentY) < abs($1.value - contentY)
        }) else { return }
        if vm.voiceFollowActive {
            // Re-anchor voice tracking here; stay in voice-follow.
            vm.reseatVoice(to: nearest.key)
            if let offset = centerOffset(forParagraph: nearest.key) {
                vm.playbackOffset = offset
                viewOffset = offset
            }
        } else {
            movePlayback(to: nearest.key)
            vm.play()
        }
    }

    private func movePlayback(to index: Int) {
        cancelReturn()
        isPreviewing = false
        if let offset = centerOffset(forParagraph: index) {
            vm.playbackOffset = offset
            viewOffset = offset
        }
        vm.currentIndex = index
    }

    private func adjustTextSize(_ delta: Double) {
        settings.textScale = min(max(settings.textScale + delta, 0), 1)
    }

    // MARK: - Gestures

    /// Drag = preview only. It moves the view, never the playback point, so the
    /// highlight and pacing keep advancing underneath. After `returnDelay` of no
    /// input, the view animates back to the live playback spot.
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                isPreviewing = true
                cancelReturn()
                let start = dragStartOffset ?? viewOffset
                if dragStartOffset == nil { dragStartOffset = start }
                viewOffset = min(max(start - value.translation.height, 0), vm.maxOffset)
                vm.wakeChrome()
            }
            .onEnded { _ in
                dragStartOffset = nil
                scheduleReturn()
            }
    }

    private func scheduleReturn() {
        cancelReturn()
        let work = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.45)) {
                viewOffset = vm.playbackOffset
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                isPreviewing = false
            }
        }
        returnWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + returnDelay, execute: work)
    }

    private func cancelReturn() {
        returnWork?.cancel()
        returnWork = nil
    }

    // MARK: - Overlays

    /// Shown while previewing: a tap returns immediately to the live spot.
    private var returnToLiveButton: some View {
        VStack {
            Button {
                cancelReturn()
                withAnimation(.easeInOut(duration: 0.35)) { viewOffset = vm.playbackOffset }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { isPreviewing = false }
            } label: {
                Label("Back to current", systemImage: "arrow.down.to.line")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Theme.onAccent)
                    .padding(.horizontal, Spacing.lg)
                    .frame(height: 40)
                    .background(Theme.accent, in: Capsule())
                    .floatShadow()
            }
            .buttonStyle(.plain)
            Spacer()
        }
        .padding(.top, 64)
    }

    /// Only surface status that needs attention (model download / errors) — the
    /// "Listening" pill in the chrome already covers the normal active state.
    private var showsVoiceStatus: Bool {
        !vm.voiceStatus.isEmpty && !vm.voiceStatus.hasPrefix("Listening")
    }

    private var voiceStatusPill: some View {
        Text(vm.voiceStatus)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Theme.surface, in: Capsule())
            .cardShadow()
    }

    private var cueChip: AnyView? {
        guard let citation = vm.upcomingCitation else { return nil }
        return AnyView(
            CueChip(citation: citation, forceExpanded: vm.cueShouldExpand) {
                if let url = citation.url ?? linker.url(for: citation) {
                    UIApplication.shared.open(url)
                }
            }
        )
    }

    // MARK: - Layout

    /// Reading-column side padding: generous at full width, tighter when narrow
    /// (Split View) so the column stays readable.
    static func sidePadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<480: return 24
        case ..<760: return 56
        default: return 110
        }
    }
}

// MARK: - Geometry plumbing

private enum ReaderSpace { static let name = "reader" }

private struct ParagraphFrameKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] = [:]
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
