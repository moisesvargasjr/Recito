//
//  ScriptureCitation.swift
//  Recito
//
//  A scripture reference detected in imported text (e.g. "Ps. 37:7",
//  "Salmo 83:18", "2 Tim. 2:5"). The raw text preserves the original spelling
//  and accents; `displayShort` is the normalized chip label.
//

import Foundation

struct ScriptureCitation: Codable, Equatable, Hashable, Identifiable {
    /// The reference exactly as it appeared in the source (accents preserved).
    let rawText: String
    /// Normalized lowercase book key, e.g. "psalms".
    let bookCanonical: String
    let chapter: Int
    let verseStart: Int
    let verseEnd: Int?
    /// Compact label for the cue chip, e.g. "Ps. 37:7" or "Ps. 37:7-9".
    let displayShort: String

    /// True when the reference was written as a Markdown link — the author's
    /// signal that they intend to read it. Only linked citations are cued.
    var isLinked: Bool = false
    /// The author's own link target (from the Markdown link), if any. Preferred
    /// over the generated deep link when opening.
    var url: URL? = nil

    var id: String {
        let range = verseEnd.map { "-\($0)" } ?? ""
        return "\(bookCanonical) \(chapter):\(verseStart)\(range)"
    }

    /// A copy marked as an active (read-aloud) cue carrying the author's URL.
    func activated(url: URL?) -> ScriptureCitation {
        var copy = self
        copy.isLinked = true
        copy.url = url
        return copy
    }
}
