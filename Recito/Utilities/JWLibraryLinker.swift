//
//  JWLibraryLinker.swift
//  Recito
//
//  ScriptureLinker that builds a jw.org "finder" deep link. If JW Library is
//  installed it opens there; otherwise it degrades gracefully to the web. All
//  URL-scheme knowledge is isolated here so it can be swapped or removed.
//

import Foundation

struct JWLibraryLinker: ScriptureLinker {
    /// Locale code for the finder link (S = Spanish, E = English).
    var localeCode: String = "S"

    func url(for citation: ScriptureCitation) -> URL? {
        guard let code = bibleCode(for: citation) else { return nil }
        var components = URLComponents(string: "https://www.jw.org/finder")
        components?.queryItems = [
            URLQueryItem(name: "wtlocale", value: localeCode),
            URLQueryItem(name: "prefer", value: "lang"),
            URLQueryItem(name: "pub", value: "nwtsty"),
            URLQueryItem(name: "bible", value: code),
        ]
        return components?.url
    }

    /// JW "BBCCCVVV" code: 2-digit book, 3-digit chapter, 3-digit verse.
    private func bibleCode(for citation: ScriptureCitation) -> String? {
        guard let number = BibleBookCatalog.bookNumber(for: citation.bookCanonical) else { return nil }
        return String(format: "%02d%03d%03d", number, citation.chapter, citation.verseStart)
    }
}
