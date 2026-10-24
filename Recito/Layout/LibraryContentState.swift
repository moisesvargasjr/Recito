//
//  LibraryContentState.swift
//  Recito
//
//  What the library body shows: the grid, or one of the empty states. Pure so
//  the choice is unit-tested independently of the view.
//

import Foundation

enum LibraryContentState: Equatable, Sendable {
    case grid
    /// The library has no talks at all.
    case noTalks
    /// Every talk is hidden and Show Hidden is off.
    case allHidden
    /// A search is active and nothing matched.
    case noResults(query: String)

    static func resolve(displayCount: Int, totalCount: Int, searchText: String) -> LibraryContentState {
        guard displayCount == 0 else { return .grid }
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty { return .noResults(query: query) }
        return totalCount == 0 ? .noTalks : .allHidden
    }
}
