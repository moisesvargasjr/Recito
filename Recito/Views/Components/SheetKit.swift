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
    var identifier: String? = nil
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
                            .font(.body)
                            .foregroundStyle(Theme.ink)
                        if let subtitle {
                            Text(subtitle)
                                .font(.footnote)
                                .foregroundStyle(Theme.ink3)
                        }
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.ink3)
                        .accessibilityHidden(true)
                }
                .padding(.horizontal, Spacing.lg)
                .padding(.vertical, Spacing.md)
                .frame(minHeight: Spacing.hitTarget)
                .contentShape(Rectangle())
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .optionalAccessibilityIdentifier(identifier)
    }
}

// MARK: - Detents

/// Shared sheet sizing: compact height (landscape phones, short displays) only
/// offers `.large` so controls aren't squeezed; otherwise `.medium` + `.large`,
/// starting at `initial`. The drag indicator is always visible.
struct AdaptiveSheetDetents: ViewModifier {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var selection: PresentationDetent

    init(initial: PresentationDetent) {
        _selection = State(initialValue: initial)
    }

    func body(content: Content) -> some View {
        let isCompactHeight = verticalSizeClass == .compact
        let effective = Binding<PresentationDetent>(
            get: { isCompactHeight ? .large : selection },
            set: { selection = $0 }
        )
        return content
            .presentationDetents(isCompactHeight ? [.large] : [.medium, .large], selection: effective)
            .presentationDragIndicator(.visible)
    }
}

extension View {
    func adaptiveSheetDetents(initial: PresentationDetent = .medium) -> some View {
        modifier(AdaptiveSheetDetents(initial: initial))
    }
}

// MARK: - Keyboard

/// A trailing "Done" button above the keyboard that ends text editing.
struct KeyboardDoneToolbar: ToolbarContent {
    let identifier: String
    let action: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done", action: action)
                .fontWeight(.semibold)
                .accessibilityIdentifier(identifier)
                .accessibilityHint("Hides the keyboard")
        }
    }
}

// MARK: - Accessibility

extension View {
    /// Applies an accessibility identifier only when one is given.
    @ViewBuilder
    func optionalAccessibilityIdentifier(_ identifier: String?) -> some View {
        if let identifier {
            accessibilityIdentifier(identifier)
        } else {
            self
        }
    }
}
