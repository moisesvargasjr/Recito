//
//  LibraryViewModel.swift
//  Recito
//
//  Search/sort over the talk library. Most-recently-opened sorts first and is
//  the talk that carries the "Continue" badge.
//

import Foundation
import Combine

final class LibraryViewModel: ObservableObject {
    @Published var searchText: String = ""

    /// Talks sorted most-recent-first, filtered by the search text.
    func displayTalks(from talks: [Talk]) -> [Talk] {
        let sorted = talks.sorted { $0.lastOpenedAt > $1.lastOpenedAt }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return sorted }
        return sorted.filter {
            $0.title.localizedCaseInsensitiveContains(query)
                || $0.sourceText.localizedCaseInsensitiveContains(query)
        }
    }

    /// The talk that should show the "Continue" badge (the most recent), if any.
    func recentTalkID(from talks: [Talk]) -> Talk.ID? {
        talks.max(by: { $0.lastOpenedAt < $1.lastOpenedAt })?.id
    }
}
