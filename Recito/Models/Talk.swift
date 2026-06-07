//
//  Talk.swift
//  Recito
//
//  A saved talk. `sourceText` is the single source of truth — both reading
//  models are derived from it via MarkdownParser, so only the source and light
//  metadata are persisted (no serialized derived structures).
//

import Foundation

struct Talk: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var sourceText: String
    var preferredMode: DocumentMode
    /// Talk time limit in seconds (pacing). Default 30 minutes.
    var timeLimit: TimeInterval
    var createdAt: Date
    var lastOpenedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        sourceText: String,
        preferredMode: DocumentMode = .script,
        timeLimit: TimeInterval = 30 * 60,
        createdAt: Date = Date(),
        lastOpenedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.sourceText = sourceText
        self.preferredMode = preferredMode
        self.timeLimit = timeLimit
        self.createdAt = createdAt
        self.lastOpenedAt = lastOpenedAt
    }

    /// Parse the source into both reading models. Callers that use this in a hot
    /// path (the readers) should cache the result rather than re-parsing.
    var parsed: ParsedDocument { MarkdownParser.parse(sourceText) }

    /// First few non-empty lines, for the card thumbnail preview.
    func previewLines(_ limit: Int = 5) -> [String] {
        sourceText
            .split(separator: "\n", omittingEmptySubsequences: true)
            .prefix(limit)
            .map { MarkdownParser.stripMarkers(String($0)) }
    }

    var timeLimitLabel: String {
        "\(Int(timeLimit / 60)) min"
    }
}
