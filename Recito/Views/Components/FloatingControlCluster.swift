//
//  FloatingControlCluster.swift
//  Recito
//
//  The floating reader control bar: A− / Aa / A+ · prev / play-pause / next ·
//  timer + on-pace. Outline mode uses labeled Prev/Next buttons.
//

import SwiftUI

struct FloatingControlCluster: View {
    let isPlaying: Bool
    var labeledPrevNext: Bool = false
    let elapsed: TimeInterval
    let timeLimit: TimeInterval
    /// Optional pacing readout ("~58% · on pace"); shown once pacing is wired.
    var pace: PaceState? = nil

    let onSizeDown: () -> Void
    let onAa: () -> Void
    let onSizeUp: () -> Void
    let onPrev: () -> Void
    let onTogglePlay: () -> Void
    let onNext: () -> Void
    var onPaceTap: (() -> Void)? = nil

    var body: some View {
        // On narrow widths (Split View), trim outer groups first — drop the
        // size group, then the timer — but always keep the transport controls.
        ViewThatFits(in: .horizontal) {
            clusterRow(showSize: true, showTimer: true)
            clusterRow(showSize: false, showTimer: true)
            clusterRow(showSize: false, showTimer: false)
        }
        .padding(Spacing.sm)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .floatShadow()
    }

    private func clusterRow(showSize: Bool, showTimer: Bool) -> some View {
        HStack(spacing: Spacing.sm) {
            if showSize {
                sizeGroup
                divider
            }
            transportGroup
            if showTimer {
                divider
                timerReadout
            }
        }
    }

    private var sizeGroup: some View {
        HStack(spacing: Spacing.sm) {
            circleButton("textformat.size.smaller", action: onSizeDown)
            AaButton(action: onAa)
            circleButton("textformat.size.larger", action: onSizeUp)
        }
    }

    private var transportGroup: some View {
        HStack(spacing: Spacing.sm) {
            if labeledPrevNext {
                labeledButton("Prev", system: "chevron.left", filled: false, action: onPrev)
                labeledButton("Next", system: "chevron.right", filled: true, action: onNext)
            } else {
                circleButton("backward.frame", action: onPrev)
                playButton
                circleButton("forward.frame", action: onNext)
            }
        }
    }

    private var playButton: some View {
        Button(action: onTogglePlay) {
            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Theme.onAccent)
                .frame(width: 60, height: 54)
                .background(Theme.accent, in: RoundedRectangle(cornerRadius: Radius.control))
        }
        .buttonStyle(.plain)
    }

    private var timerReadout: some View {
        Button {
            onPaceTap?()
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(elapsed.clockString)
                        .font(Typography.timer)
                        .foregroundStyle(Theme.ink)
                    Text("/ \(timeLimit.clockString)")
                        .font(.system(size: 15, weight: .regular).monospacedDigit())
                        .foregroundStyle(Theme.ink2)
                }
                if let pace {
                    HStack(spacing: 5) {
                        Circle().fill(statusColor(pace.status)).frame(width: 7, height: 7)
                        Text(pace.status.label)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(statusColor(pace.status))
                        Text("· \(pace.remaining.clockString) left")
                            .font(.system(size: 13, weight: .regular).monospacedDigit())
                            .foregroundStyle(Theme.ink2)
                    }
                    if let projected = pace.projectedTotal {
                        Text("finish ~\(projected.clockString)")
                            .font(.system(size: 12, weight: .regular).monospacedDigit())
                            .foregroundStyle(projected > pace.timeLimit ? Theme.warning : Theme.ink3)
                    }
                }
            }
            .padding(.horizontal, Spacing.sm)
        }
        .buttonStyle(.plain)
        .disabled(onPaceTap == nil)
    }

    private func statusColor(_ status: PaceStatus) -> Color {
        switch status {
        case .behind: return Theme.warning
        case .onPace: return Theme.good
        case .ahead: return Theme.accent
        }
    }

    private var divider: some View {
        Rectangle()
            .fill(Theme.separator)
            .frame(width: 1.5, height: 32)
    }

    private func circleButton(_ system: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(Theme.ink2)
                .frame(width: Spacing.hitTarget, height: Spacing.hitTarget)
                .background(Theme.surface2, in: Circle())
        }
        .buttonStyle(.plain)
    }

    private func labeledButton(_ title: String, system: String, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: system)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(filled ? Theme.onAccent : Theme.ink)
                .padding(.horizontal, Spacing.md)
                .frame(height: Spacing.hitTarget)
                .background(filled ? Theme.accent : Theme.surface2,
                           in: RoundedRectangle(cornerRadius: Radius.control))
        }
        .buttonStyle(.plain)
    }
}
