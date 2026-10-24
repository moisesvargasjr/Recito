//
//  TalkFactory.swift
//  RecitoTests
//
//  Small builders for talks used across suites.
//

import Foundation
@testable import Recito

enum TalkFactory {
    /// Four paragraphs; paragraph 2 holds a linked (read-aloud) citation.
    static let citedScript = """
    First paragraph of the talk.

    Second paragraph keeps going.

    Third paragraph reads [Ps. 37:7](https://example.com/ps) aloud.

    Fourth paragraph closes.
    """

    /// Twenty distinctive words across two paragraphs, for voice alignment.
    static let voiceScript = """
    alpha bravo charlie delta echo foxtrot golf hotel india juliet

    kilo lima mike november oscar papa quebec romeo sierra tango
    """

    static let outline = """
    1. First point
       - Sub point
    2. Second point
    3. Third point
    """

    static func talk(
        title: String = "Test Talk",
        text: String = citedScript,
        mode: DocumentMode = .script,
        timeLimit: TimeInterval = 60,
        source: TalkSource = .local,
        isHidden: Bool = false
    ) -> Talk {
        Talk(
            title: title,
            sourceText: text,
            preferredMode: mode,
            timeLimit: timeLimit,
            createdAt: Date(timeIntervalSince1970: 1_700_000_000),
            lastOpenedAt: Date(timeIntervalSince1970: 1_700_000_000),
            source: source,
            isHidden: isHidden
        )
    }
}
