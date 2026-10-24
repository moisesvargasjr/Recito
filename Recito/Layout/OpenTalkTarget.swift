//
//  OpenTalkTarget.swift
//  Recito
//
//  Resolves the `-openTalk <uuid>` launch argument to a talk in the library.
//  UUID parsing is case-insensitive; surrounding whitespace is ignored.
//

import Foundation

enum OpenTalkTarget {
    static func talk(matching rawID: String?, in talks: [Talk]) -> Talk? {
        guard let rawID,
              let id = UUID(uuidString: rawID.trimmingCharacters(in: .whitespacesAndNewlines))
        else { return nil }
        return talks.first { $0.id == id }
    }
}
