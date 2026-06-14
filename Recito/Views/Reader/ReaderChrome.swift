//
//  ReaderChrome.swift
//  Recito
//
//  Auto-hiding overlay shared by both readers: a back affordance (top-left), a
//  spot for the scripture cue chip (top-right, added with cues), and the
//  floating control cluster (bottom-center).
//

import SwiftUI

struct ReaderChrome: View {
    @ObservedObject var vm: ReaderViewModel
    @Environment(\.colorScheme) private var scheme
    var labeledPrevNext: Bool = false
    var title: String? = nil

    let onClose: () -> Void
    let onAa: () -> Void
    let onPrev: () -> Void
    let onNext: () -> Void
    let onSizeDown: () -> Void
    let onSizeUp: () -> Void
    var onPaceTap: (() -> Void)? = nil

    // Voice-follow (only offered when available, in script mode). When set, the
    // Auto/Voice switch appears and the play button drives the active mode.
    var voiceAvailable: Bool = false
    /// Running state of the active follow mode, for the play/pause icon. Falls
    /// back to `vm.isPlaying` when not supplied (outline reader).
    var isRunning: Bool? = nil
    /// Mode-aware play/pause handler. Falls back to `vm.togglePlay()`.
    var onTogglePlay: (() -> Void)? = nil

    /// Optional top-right accessory (the scripture cue chip, wired in Stage 9).
    var topTrailing: AnyView? = nil

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center, spacing: Spacing.md) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                        .frame(width: Spacing.hitTarget, height: Spacing.hitTarget)
                        .background(Theme.surface2, in: Circle())
                }
                .buttonStyle(.plain)

                if let title {
                    Text(title)
                        .font(Typography.navTitle)
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .layoutPriority(-1)
                }

                Spacer()

                if voiceAvailable { followModeSwitch }

                modeToggle

                if let topTrailing { topTrailing }
            }
            .padding(.horizontal, Spacing.xl)
            // Clear the iPadOS multitasking / window controls at the top.
            .padding(.top, Spacing.xxl)

            // Instruction caption — visible while the chrome is up (it shares the
            // chrome's fade), so the controls explain themselves, then get out of
            // the way. Only where the play button exists (script reader).
            if !labeledPrevNext {
                Text(instructionText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.ink2)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, 6)
                    .background(Theme.surface2, in: Capsule())
                    .padding(.top, Spacing.sm)
            }

            Spacer()

            if vm.voiceFollowActive {
                listeningIndicator
            }

            if vm.isHoldingForScripture {
                Label("Reading scripture — tap play to continue", systemImage: "book")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Theme.accentSoft(scheme), in: Capsule())
                    .padding(.bottom, Spacing.sm)
            }

            FloatingControlCluster(
                isPlaying: isRunning ?? vm.isPlaying,
                labeledPrevNext: labeledPrevNext,
                elapsed: vm.elapsed,
                timeLimit: vm.timeLimit,
                pace: vm.pace,
                onSizeDown: onSizeDown,
                onAa: onAa,
                onSizeUp: onSizeUp,
                onPrev: onPrev,
                onTogglePlay: onTogglePlay ?? { vm.togglePlay() },
                onNext: onNext,
                onPaceTap: onPaceTap
            )
            .padding(.bottom, Spacing.xl)
        }
        .opacity(vm.chromeVisible ? 1 : 0)
        .animation(.easeInOut(duration: 0.25), value: vm.chromeVisible)
        .allowsHitTesting(vm.chromeVisible)
    }

    /// Live "listening" indicator: bars that continuously animate while active
    /// and grow with the mic level, so it's always a clear "it's on" signal.
    private var listeningIndicator: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            HStack(spacing: 5) {
                ForEach(0..<5, id: \.self) { i in
                    Capsule()
                        .fill(Theme.accent)
                        .frame(width: 3, height: barHeight(i, t))
                }
                Text("Listening…")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.accent)
            }
            .padding(.horizontal, Spacing.md)
            .padding(.vertical, Spacing.sm)
            .background(Theme.accentSoft(scheme), in: Capsule())
            .padding(.bottom, Spacing.sm)
        }
    }

    private func barHeight(_ index: Int, _ t: Double) -> CGFloat {
        let wave = (sin(t * 7 + Double(index) * 0.9) + 1) / 2     // 0…1, always moving
        let level = Double(max(vm.audioLevel, 0.2))               // floor so it never freezes
        return 6 + CGFloat(wave * level * 20)
    }

    /// Contextual one-liner that ties the play button to the active mode.
    private var instructionText: String {
        if voiceAvailable {
            switch vm.followMode {
            case .voice:
                return vm.voiceFollowActive
                    ? "Listening — play/pause stops listening and holds the timer"
                    : "Voice-follow — press play to track your speech"
            case .autoScroll:
                return vm.isPlaying
                    ? "Auto-scrolling — press pause to stop"
                    : "Auto-scroll — press play for time-paced scrolling"
            }
        }
        return vm.isPlaying ? "Press pause to stop" : "Press play to auto-scroll"
    }

    /// Auto-scroll ↔ Voice switch. Picks the follow mode; the play button starts
    /// it. Selecting Voice does not open the mic until you press play.
    private var followModeSwitch: some View {
        HStack(spacing: 2) {
            modeSegment(.autoScroll)
            modeSegment(.voice)
        }
        .padding(2)
        .background(Theme.surface2, in: Capsule())
    }

    private func modeSegment(_ m: FollowMode) -> some View {
        let selected = vm.followMode == m
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { vm.setFollowMode(m) }
        } label: {
            Label(m.label, systemImage: m.symbol)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(selected ? Theme.onAccent : Theme.accent)
                .padding(.horizontal, Spacing.sm)
                .frame(height: 32)
                .background(selected ? Theme.accent : Color.clear, in: Capsule())
        }
        .buttonStyle(.plain)
    }

    /// Flip between Script and Outline mode on the current talk.
    private var modeToggle: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { vm.switchMode() }
        } label: {
            Label(vm.mode.label, systemImage: vm.mode.symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .padding(.horizontal, Spacing.md)
                .frame(height: 36)
                .background(Theme.accentSoft(scheme), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}
