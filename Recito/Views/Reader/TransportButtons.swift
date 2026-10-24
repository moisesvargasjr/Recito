//
//  TransportButtons.swift
//  Recito
//
//  Prev / Play-Pause / Next, shared by the system toolbar (compact labels) and
//  the tabletop transport panel (large buttons), plus the one-shot command the
//  container sends to the script reader for paragraph jumps.
//

import SwiftUI

/// One transport control: its title, symbol and accessibility id.
enum TransportControl: CaseIterable {
    case previous, playPause, next

    func title(isRunning: Bool) -> String {
        switch self {
        case .previous: return "Previous"
        case .playPause: return isRunning ? "Pause" : "Play"
        case .next: return "Next"
        }
    }

    func systemImage(isRunning: Bool) -> String {
        switch self {
        case .previous: return "backward.frame"
        case .playPause: return isRunning ? "pause.fill" : "play.fill"
        case .next: return "forward.frame"
        }
    }

    var accessibilityID: String {
        switch self {
        case .previous: return AXID.Reader.prev
        case .playPause: return AXID.Reader.play
        case .next: return AXID.Reader.next
        }
    }
}

/// A transport request from the container to the active reader. A fresh id
/// makes repeated identical requests distinct for `onChange`.
struct ReaderCommand: Equatable {
    enum Kind: Equatable {
        case jump(Int)
    }

    let kind: Kind
    let id = UUID()
}

/// Toolbar-sized transport button (`Label` so the system can show the title
/// when it moves the item into overflow or a side bar).
struct TransportButton: View {
    let control: TransportControl
    var isRunning: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(control.title(isRunning: isRunning),
                  systemImage: control.systemImage(isRunning: isRunning))
        }
        .accessibilityIdentifier(control.accessibilityID)
    }
}

/// Large prev / play / next row for the tabletop panel.
struct TransportButtons: View {
    let showsPlay: Bool
    let isRunning: Bool
    let onPrevious: () -> Void
    let onTogglePlay: () -> Void
    let onNext: () -> Void

    @ScaledMetric(relativeTo: .title) private var sideSize: CGFloat = 56
    @ScaledMetric(relativeTo: .title) private var playSize: CGFloat = 72

    var body: some View {
        HStack(spacing: Spacing.xl) {
            bigButton(.previous, size: sideSize, glyph: .title2, filled: false, action: onPrevious)
            if showsPlay {
                bigButton(.playPause, size: playSize, glyph: .title, filled: true, action: onTogglePlay)
            }
            bigButton(.next, size: sideSize, glyph: .title2, filled: false, action: onNext)
        }
    }

    private func bigButton(
        _ control: TransportControl,
        size: CGFloat,
        glyph: Font.TextStyle,
        filled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: control.systemImage(isRunning: isRunning))
                .font(.system(glyph, weight: .semibold))
                .foregroundStyle(filled ? Theme.onAccent : Theme.ink)
                .frame(width: max(size, Spacing.hitTarget), height: max(size, Spacing.hitTarget))
                .background(filled ? Theme.accent : Theme.surface2, in: Circle())
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(control.title(isRunning: isRunning))
        .accessibilityIdentifier(control.accessibilityID)
    }
}
