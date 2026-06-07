//
//  SheetKit.swift
//  Recito
//
//  Shared building blocks for the centered form sheets (Import, Pacing, Text &
//  Display): an ALL-CAPS group header, a grouped surface container, and a
//  navigable list row.
//

import SwiftUI

/// ALL-CAPS section header, e.g. "PASTE YOUR SCRIPT".
struct GroupHeaderText: View {
    let title: String
    init(_ title: String) { self.title = title }

    var body: some View {
        Text(title.uppercased())
            .font(Typography.groupHeader)
            .tracking(0.6)
            .foregroundStyle(Theme.ink3)
            .padding(.horizontal, Spacing.lg)
            .padding(.bottom, Spacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// A grouped surface container (card background + radius + shadow).
struct SheetGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Radius.group))
        .cardShadow()
    }
}

/// A tappable list row with a title, optional subtitle, and a trailing chevron.
struct SheetNavRow: View {
    let title: String
    var subtitle: String? = nil
    var showDivider: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                if showDivider {
                    Divider().background(Theme.separator)
                }
                HStack(spacing: Spacing.md) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 17))
                            .foregroundStyle(Theme.ink)
                        if let subtitle {
                            Text(subtitle)
                                .font(.system(size: 13))
                                .foregroundStyle(Theme.ink3)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.ink3)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
            }
        }
        .buttonStyle(.plain)
    }
}
