//
//  TalkCardView.swift
//  Recito
//
//  A library talk card: thumbnail preview + title + mode tag + time pill. The
//  most-recent talk carries a blue "▸ Continue" badge and an accent ring.
//  Height is a minimum (LayoutMetrics.cardMinHeight), so Dynamic Type can grow it.
//

import SwiftUI

struct TalkCardView: View {
    let talk: Talk
    let isRecent: Bool
    var minHeight: CGFloat = LayoutMetrics.cardMinHeight(isCompactHeight: false)
    let onTap: () -> Void

    /// Vertical space reserved for title + tags + padding at default text size;
    /// the thumbnail gets the rest of the card's minimum height.
    private static let textBlockAllowance: CGFloat = 104

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ScriptThumbnail(title: talk.title, lines: talk.previewLines())
                    .frame(minHeight: max(Spacing.hitTarget, minHeight - Self.textBlockAllowance),
                           maxHeight: .infinity)

                Text(talk.title)
                    .font(.headline)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(2)

                tags
            }
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity, minHeight: minHeight, maxHeight: .infinity, alignment: .top)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Radius.card))
            .overlay(alignment: .topTrailing) {
                if isRecent { continueBadge.padding(Spacing.md) }
            }
            .overlay {
                if isRecent {
                    RoundedRectangle(cornerRadius: Radius.card)
                        .strokeBorder(Theme.accent, lineWidth: 2)
                }
            }
            .cardShadow()
            .contentShape(RoundedRectangle(cornerRadius: Radius.card))
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
        .accessibilityHint("Opens the reader")
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier(AXID.Library.card(talk.id.uuidString))
    }

    /// Tags side by side, stacked when large text would overflow the card.
    private var tags: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: Spacing.sm) {
                ModeTag(mode: talk.preferredMode)
                TimePill(label: talk.timeLimitLabel)
                Spacer(minLength: 0)
            }
            VStack(alignment: .leading, spacing: Spacing.xs) {
                ModeTag(mode: talk.preferredMode)
                TimePill(label: talk.timeLimitLabel)
            }
        }
    }

    private var accessibilityText: String {
        let parts = [
            isRecent ? "Continue" : nil,
            talk.title,
            talk.preferredMode.label,
            talk.timeLimitLabel,
            talk.isHidden ? "Hidden" : nil,
        ]
        return parts.compactMap { $0 }.joined(separator: ", ")
    }

    private var continueBadge: some View {
        Label("Continue", systemImage: "play.fill")
            .labelStyle(.titleAndIcon)
            .font(.caption.weight(.bold))
            .foregroundStyle(Theme.onAccent)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Theme.accent, in: Capsule())
    }
}
