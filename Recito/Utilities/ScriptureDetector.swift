//
//  ScriptureDetector.swift
//  Recito
//
//  Detects scripture references in free text. A match requires a *known* book
//  token (from BibleBookCatalog) immediately before a `chapter:verse` pair, so
//  bare number pairs like the "12:30" timer never produce a false positive.
//

import Foundation

enum ScriptureDetector {
    // Optional 1–3 numeric prefix ("2 " in "2 Tim"), a word with optional dot,
    // whitespace, then chapter:verse with an optional verse range. The leading
    // lookbehind keeps us from starting mid-word.
    private static let pattern =
        #"(?<![\p{L}\d])((?:[1-3]\s+)?\p{L}+\.?)\s+(\d{1,3}):(\d{1,3})(?:[-–—](\d{1,3}))?"#

    private static let regex = try! NSRegularExpression(pattern: pattern, options: [])

    private static let linkRegex = try! NSRegularExpression(pattern: #"\[([^\]]+)\]\(([^)]+)\)"#)

    /// Normalized common EN/ES words that collide with short book abbreviations;
    /// only honored as books when capitalized in the source.
    private static let commonWords: Set<String> = [
        "is", "am", "as", "a", "an", "the", "in", "on", "at", "to", "of", "it",
        "he", "we", "be", "do", "so", "no", "or", "my", "by", "up", "us", "me",
        "es", "el", "la", "de", "en", "un", "lo", "le", "al", "se", "su", "mi",
        "tu", "ya", "os", "ni",
    ]

    /// Replace Markdown links `[label](url)` with just their label, for display.
    static func stripLinks(_ text: String) -> String {
        let ns = text as NSString
        return linkRegex.stringByReplacingMatches(
            in: text,
            range: NSRange(location: 0, length: ns.length),
            withTemplate: "$1"
        )
    }

    /// Detect citations in *raw* block text, honoring Markdown links: a scripture
    /// inside a `[label](url)` link is marked `isLinked` and carries that URL.
    /// Bare (unlinked) references are detected but left inactive.
    static func detect(inRaw raw: String) -> [ScriptureCitation] {
        // Map citation id → author URL for any reference written as a link.
        var linkURLs: [String: URL?] = [:]
        let ns = raw as NSString
        linkRegex.enumerateMatches(in: raw, range: NSRange(location: 0, length: ns.length)) { match, _, _ in
            guard let match, match.numberOfRanges >= 3 else { return }
            let label = ns.substring(with: match.range(at: 1))
            let href = ns.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespaces)
            for citation in detect(in: label) {
                linkURLs[citation.id] = URL(string: href)
            }
        }

        // Detect over the link-stripped text so positions/order stay natural and
        // the link labels are still seen.
        return detect(in: stripLinks(raw)).map { citation in
            if let url = linkURLs[citation.id] {
                return citation.activated(url: url)
            }
            return citation
        }
    }

    /// All scripture citations found in `text`, in order of appearance.
    static func detect(in text: String) -> [ScriptureCitation] {
        guard !text.isEmpty else { return [] }

        // Fold accents + lowercase for matching; this is length-preserving for
        // precomposed Latin text, so NSRanges map back to the original.
        let folded = text.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        let foldedNS = folded as NSString
        let originalNS = text as NSString
        let full = NSRange(location: 0, length: foldedNS.length)

        var results: [ScriptureCitation] = []

        regex.enumerateMatches(in: folded, options: [], range: full) { match, _, _ in
            guard let match,
                  match.numberOfRanges >= 4 else { return }

            let bookToken = foldedNS.substring(with: match.range(at: 1))
            let normalizedToken = BibleBookCatalog.normalize(bookToken)

            // Common words collide with 2-letter abbreviations ("is"→Isaiah,
            // "am"→Amos, "en"/"el"…). Reject them when written lowercase (a real
            // citation capitalizes the book, e.g. "Is. 12:30").
            if Self.commonWords.contains(normalizedToken) {
                let original = originalNS.substring(with: match.range(at: 1))
                if original.first?.isUppercase != true { return }
            }

            guard let book = BibleBookCatalog.normalizedLookup[normalizedToken]
            else { return }

            let chapter = Int(foldedNS.substring(with: match.range(at: 2))) ?? 0
            let verseStart = Int(foldedNS.substring(with: match.range(at: 3))) ?? 0
            var verseEnd: Int?
            let endRange = match.range(at: 4)
            if endRange.location != NSNotFound {
                verseEnd = Int(foldedNS.substring(with: endRange))
            }

            // Raw text taken from the original (accents/case preserved).
            let raw = originalNS.substring(with: match.range)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let rangeSuffix = verseEnd.map { "-\($0)" } ?? ""
            let displayShort = "\(book.displayShort) \(chapter):\(verseStart)\(rangeSuffix)"

            results.append(
                ScriptureCitation(
                    rawText: raw,
                    bookCanonical: book.canonical,
                    chapter: chapter,
                    verseStart: verseStart,
                    verseEnd: verseEnd,
                    displayShort: displayShort
                )
            )
        }

        return results
    }
}
