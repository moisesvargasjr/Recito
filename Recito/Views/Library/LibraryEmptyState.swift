//
//  LibraryEmptyState.swift
//  Recito
//
//  Shown instead of the grid when there's nothing to list: an empty library,
//  every talk hidden, or a search with no matches. Always offers Import.
//

import SwiftUI

struct LibraryEmptyState: View {
    let state: LibraryContentState
    let onImport: () -> Void
    var onShowHidden: (() -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                Image(systemName: symbol)
                    .font(.largeTitle)
                    .foregroundStyle(Theme.ink3)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.title2.bold())
                    .foregroundStyle(Theme.ink)
                Text(message)
                    .font(.body)
                    .foregroundStyle(Theme.ink2)
                actions
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: 420)
            .padding(.horizontal, Spacing.xl)
            .padding(.vertical, Spacing.xxxl)
            .frame(maxWidth: .infinity)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AXID.Library.emptyState)
    }

    private var actions: some View {
        VStack(spacing: Spacing.sm) {
            Button(action: onImport) {
                Label("Import a talk", systemImage: "plus")
                    .frame(minHeight: Spacing.hitTarget)
                    .padding(.horizontal, Spacing.sm)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier(AXID.Library.emptyStateImport)

            if state == .allHidden, let onShowHidden {
                Button("Show Hidden", action: onShowHidden)
                    .frame(minHeight: Spacing.hitTarget)
            }
        }
        .padding(.top, Spacing.sm)
    }

    private var symbol: String {
        switch state {
        case .noResults: return "magnifyingglass"
        case .allHidden: return "eye.slash"
        case .noTalks, .grid: return "text.book.closed"
        }
    }

    private var title: String {
        switch state {
        case .noResults: return "No Results"
        case .allHidden: return "All Talks Hidden"
        case .noTalks, .grid: return "No Talks Yet"
        }
    }

    private var message: String {
        switch state {
        case .noResults(let query):
            return "No talks match “\(query)”. Check the spelling or import a new talk."
        case .allHidden:
            return "Every talk in your library is hidden. Show hidden talks, or import a new one."
        case .noTalks, .grid:
            return "Paste a script, import a Markdown file, or follow a vault folder to get started."
        }
    }
}

#Preview("Empty, accessibility size") {
    LibraryEmptyState(state: .noTalks, onImport: {})
        .environment(\.dynamicTypeSize, .accessibility3)
}
