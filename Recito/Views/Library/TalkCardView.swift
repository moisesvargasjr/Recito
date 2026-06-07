//
//  TalkCardView.swift
//  Recito
//
//  A library talk card: thumbnail preview + title + mode tag + time pill. The
//  most-recent talk carries a blue "▸ Continue" badge and an accent ring.
//

import SwiftUI

struct TalkCardView: View {
    let talk: Talk
    let isRecent: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ScriptThumbnail(title: talk.title, lines: talk.previewLines())
                    .frame(maxHeight: .infinity)

                Text(talk.title)
                    .font(Typography.cardTitle)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)

                HStack(spacing: Spacing.sm) {
                    ModeTag(mode: talk.preferredMode)
                    TimePill(label: talk.timeLimitLabel)
                    Spacer(minLength: 0)
                }
            }
            .padding(Spacing.lg)
            .frame(height: 230)
            .frame(maxWidth: .infinity)
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
        }
        .buttonStyle(.plain)
    }

    private var continueBadge: some View {
        Label("Continue", systemImage: "play.fill")
            .labelStyle(.titleAndIcon)
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(Theme.onAccent)
            .padding(.horizontal, Spacing.sm)
            .padding(.vertical, Spacing.xs)
            .background(Theme.accent, in: Capsule())
    }
}
