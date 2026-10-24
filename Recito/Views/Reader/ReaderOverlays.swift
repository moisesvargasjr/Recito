//
//  ReaderOverlays.swift
//  Recito
//
//  In-content overlays shared by both readers: the pace bar (top), and at the
//  bottom the listening indicator, the scripture-hold note, the Resume pill
//  and the cue chip (bottom-trailing). Positions come from the region's
//  stable safe-area insets, so hiding the bars never moves them.
//

import SwiftUI

struct ReaderOverlays: View {
    @ObservedObject var vm: ReaderViewModel
    let insets: EdgeInsets
    /// False in tabletop, where the transport panel shows pace and cue.
    let showsPaceAndCue: Bool
    let onOpenScripture: (ScriptureCitation) -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            if showsPaceAndCue {
                PaceBarView(pace: vm.pace)
                    .padding(.top, insets.top)
                    .padding(.leading, insets.leading)
                    .padding(.trailing, insets.trailing)
            }
            Spacer(minLength: 0)
            bottomStack
                .padding(.leading, insets.leading + Spacing.lg)
                .padding(.trailing, insets.trailing + Spacing.lg)
                .padding(.bottom, insets.bottom + Spacing.lg)
        }
    }

    private var bottomStack: some View {
        VStack(alignment: .trailing, spacing: Spacing.sm) {
            VStack(spacing: Spacing.sm) {
                if vm.voiceFollowActive { ListeningIndicator(level: vm.audioLevel) }
                if showsHoldNote { holdNote }
                // In tabletop the transport panel carries Resume instead.
                if vm.showsResume && showsPaceAndCue { resumePill }
            }
            .frame(maxWidth: .infinity)
            if showsPaceAndCue, let citation = vm.upcomingCitation {
                CueChip(citation: citation, forceExpanded: vm.cueShouldExpand) {
                    onOpenScripture(citation)
                }
            }
        }
    }

    private var showsHoldNote: Bool {
        vm.isHoldingForScripture && !vm.showsResume && vm.presentedCitation == nil
    }

    private var holdNote: some View {
        Label("Reading scripture — tap play to continue", systemImage: "book")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Theme.accentSoft(colorScheme), in: Capsule())
            .accessibilityIdentifier(AXID.Reader.scriptureHold)
    }

    private var resumePill: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { vm.resumeAfterVerse() }
        } label: {
            Label("Resume", systemImage: "play.fill")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.onAccent)
                .padding(.horizontal, Spacing.xl)
                .frame(minHeight: Spacing.hitTarget)
                .background(Theme.accent, in: Capsule())
                .floatShadow()
        }
        .buttonStyle(.plain)
        .accessibilityHint("Continues from where you paused")
        .accessibilityIdentifier(AXID.Reader.resume)
    }
}

/// Live "listening" bars that keep moving while voice-follow is active and
/// grow with the mic level.
struct ListeningIndicator: View {
    let level: Float
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(Theme.accent)
                        .frame(width: 3, height: barHeight(i, t))
                }
                Text("Listening…")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Theme.accentSoft(colorScheme), in: Capsule())
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Listening")
        .accessibilityIdentifier(AXID.Reader.listening)
    }

    private func barHeight(_ index: Int, _ t: Double) -> CGFloat {
        let wave = (sin(t * 7 + Double(index) * 0.9) + 1) / 2
        let floor = Double(max(level, 0.2))
        return 6 + CGFloat(wave * floor * 20)
    }
}

/// Voice status that needs attention (model download, errors).
struct VoiceStatusPill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Theme.surface, in: Capsule())
            .cardShadow()
            .accessibilityIdentifier(AXID.Reader.voiceStatus)
    }
}

/// Shown while previewing elsewhere: returns to the live spot.
struct BackToCurrentButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Back to current", systemImage: "arrow.down.to.line")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.onAccent)
                .padding(.horizontal, Spacing.lg)
                .frame(minHeight: Spacing.hitTarget)
                .background(Theme.accent, in: Capsule())
                .floatShadow()
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(AXID.Reader.backToCurrent)
    }
}
