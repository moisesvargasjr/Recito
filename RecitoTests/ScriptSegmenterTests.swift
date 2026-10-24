//
//  ScriptSegmenterTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

struct ScriptSegmenterTests {
    private func block(_ kind: BlockKind, _ text: String, citations: [ScriptureCitation] = []) -> Block {
        Block(kind: kind, text: text, citations: citations)
    }

    @Test func emptyInputGivesNoSections() {
        #expect(ScriptSegmenter.segment([]).isEmpty)
    }

    @Test func everyBlockBecomesASectionInOrder() {
        let sections = ScriptSegmenter.segment([
            block(.heading(level: 1), "Title"),
            block(.paragraph, "Body"),
            block(.listItem(indent: 0), "Item"),
        ])
        #expect(sections.map(\.index) == [0, 1, 2])
        #expect(sections.map(\.text) == ["Title", "Body", "Item"])
    }

    @Test func onlyHeadingsAreFlagged() {
        let sections = ScriptSegmenter.segment([
            block(.heading(level: 2), "H"),
            block(.paragraph, "P"),
            block(.listItem(indent: 4), "L"),
        ])
        #expect(sections.map(\.isHeading) == [true, false, false])
    }

    @Test func citationsAreCarriedThrough() {
        let c = ScriptureCitation(
            rawText: "Ps. 37:7", bookCanonical: "psalms", chapter: 37, verseStart: 7,
            verseEnd: nil, displayShort: "Ps. 37:7", isLinked: true
        )
        let sections = ScriptSegmenter.segment([block(.paragraph, "x", citations: [c])])
        #expect(sections[0].citations == [c])
        #expect(sections[0].id == 0)
    }
}
