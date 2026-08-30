//
//  TalkSource.swift
//  Recito
//
//  Where a talk's text comes from. Local talks are owned by the app and edited
//  in it; vault talks mirror a Markdown file in a linked folder (an Obsidian
//  vault synced onto the device) and are refreshed from disk, never written to.
//

import Foundation

enum TalkSource: Equatable {
    /// Created in Recito — paste, file import, or the built-in samples.
    case local
    /// Mirrors a file in the linked vault folder, at this path relative to it.
    case vault(relativePath: String)

    var isVault: Bool {
        if case .vault = self { return true }
        return false
    }

    var relativePath: String? {
        if case .vault(let path) = self { return path }
        return nil
    }
}

// Encoded as a small keyed object so a future third source doesn't need a
// migration: {"kind":"local"} / {"kind":"vault","relativePath":"talks/012.md"}.
extension TalkSource: Codable {
    private enum CodingKeys: String, CodingKey { case kind, relativePath }
    private enum Kind: String, Codable { case local, vault }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .local:
            self = .local
        case .vault:
            self = .vault(relativePath: try container.decode(String.self, forKey: .relativePath))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .local:
            try container.encode(Kind.local, forKey: .kind)
        case .vault(let relativePath):
            try container.encode(Kind.vault, forKey: .kind)
            try container.encode(relativePath, forKey: .relativePath)
        }
    }
}
