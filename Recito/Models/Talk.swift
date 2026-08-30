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
    /// Local, or mirroring a file in the linked vault folder.
    var source: TalkSource
    /// Hidden from the library. Lets a non-talk file that lives in the linked
    /// folder (a craft note, a README) be dismissed without leaving the vault.
    var isHidden: Bool

    init(
        id: UUID = UUID(),
        title: String,
        sourceText: String,
        preferredMode: DocumentMode = .script,
        timeLimit: TimeInterval = 30 * 60,
        createdAt: Date = Date(),
        lastOpenedAt: Date = Date(),
        source: TalkSource = .local,
        isHidden: Bool = false
    ) {
        self.id = id
        self.title = title
        self.sourceText = sourceText
        self.preferredMode = preferredMode
        self.timeLimit = timeLimit
        self.createdAt = createdAt
        self.lastOpenedAt = lastOpenedAt
        self.source = source
        self.isHidden = isHidden
    }

    // Declared explicitly: `encode(to:)` is still synthesized against these, and
    // the custom decoder below needs them by name.
    enum CodingKeys: String, CodingKey {
        case id, title, sourceText, preferredMode, timeLimit
        case createdAt, lastOpenedAt, source, isHidden
    }

    // Talks saved before vault linking have neither key. Decode them as local
    // and visible rather than failing — a throw here would empty the library.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        sourceText = try c.decode(String.self, forKey: .sourceText)
        preferredMode = try c.decode(DocumentMode.self, forKey: .preferredMode)
        timeLimit = try c.decode(TimeInterval.self, forKey: .timeLimit)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        lastOpenedAt = try c.decode(Date.self, forKey: .lastOpenedAt)
        source = try c.decodeIfPresent(TalkSource.self, forKey: .source) ?? .local
        isHidden = try c.decodeIfPresent(Bool.self, forKey: .isHidden) ?? false
    }

    /// Parse the source into both reading models. Callers that use this in a hot
    /// path (the readers) should cache the result rather than re-parsing.
    var parsed: ParsedDocument { MarkdownParser.parse(sourceText) }

    /// First few non-empty lines, for the card thumbnail preview.
    func previewLines(_ limit: Int = 5) -> [String] {
        MarkdownParser.stripLeadingNotes(sourceText)
            .split(separator: "\n", omittingEmptySubsequences: true)
            .prefix(limit)
            .map { MarkdownParser.stripMarkers(String($0)) }
    }

    var timeLimitLabel: String {
        "\(Int(timeLimit / 60)) min"
    }
}
