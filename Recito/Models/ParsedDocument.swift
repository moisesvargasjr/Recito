//
//  ParsedDocument.swift
//  Recito
//
//  The result of parsing one source text into both reading models plus an
//  ordered list of citations (used to compute the next upcoming cue from the
//  reader's current position).
//

import Foundation

struct CitationRef: Equatable {
    let citation: ScriptureCitation
    /// Index into `scriptSections` where the citation appears.
    let sectionIndex: Int
}

struct ParsedDocument: Equatable {
    let scriptSections: [ScriptSection]
    let outlineNodes: [OutlineNode]
    let allCitations: [CitationRef]

    static let empty = ParsedDocument(scriptSections: [], outlineNodes: [], allCitations: [])

    /// The next *linked* (read-aloud) citation at or after `sectionIndex`, for
    /// the glance cue. Bare mentions are ignored.
    func nextCitation(fromSection sectionIndex: Int) -> ScriptureCitation? {
        let linked = allCitations.filter { $0.citation.isLinked }
        return linked.first { $0.sectionIndex >= sectionIndex }?.citation
            ?? linked.first?.citation
    }
}
