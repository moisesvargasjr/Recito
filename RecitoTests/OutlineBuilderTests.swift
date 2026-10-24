//
//  OutlineBuilderTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

struct OutlineBuilderTests {
    private func block(_ kind: BlockKind, _ text: String) -> Block {
        Block(kind: kind, text: text, citations: [])
    }

    @Test func emptyInputGivesNoNodes() {
        #expect(OutlineBuilder.build([]).isEmpty)
    }

    @Test func headingsAndTopLevelItemsAreNumberedPoints() {
        let nodes = OutlineBuilder.build([
            block(.heading(level: 1), "H"),
            block(.listItem(indent: 0), "A"),
            block(.listItem(indent: 1), "B"),
        ])
        #expect(nodes.map(\.number) == ["1", "2", "3"])
        #expect(nodes.map(\.level) == [0, 0, 0])
    }

    @Test func indentAtThresholdIsASubBullet() {
        let nodes = OutlineBuilder.build([
            block(.listItem(indent: 0), "A"),
            block(.listItem(indent: OutlineBuilder.subIndentThreshold), "a1"),
            block(.listItem(indent: 8), "a2"),
            block(.listItem(indent: 0), "B"),
        ])
        #expect(nodes.map(\.level) == [0, 1, 1, 0])
        #expect(nodes.map(\.number) == ["1", nil, nil, "2"])
        #expect(nodes[1].isSubBullet)
        #expect(!nodes[0].isSubBullet)
    }

    @Test func proseIsDroppedWhenStructureExists() {
        let nodes = OutlineBuilder.build([
            block(.paragraph, "prose"),
            block(.listItem(indent: 0), "A"),
            block(.paragraph, "more prose"),
        ])
        #expect(nodes.map(\.text) == ["A"])
    }

    @Test func pureProseFallsBackToOnePointPerParagraph() {
        let nodes = OutlineBuilder.build([block(.paragraph, "one"), block(.paragraph, "two")])
        #expect(nodes.map(\.text) == ["one", "two"])
        #expect(nodes.map(\.number) == ["1", "2"])
        #expect(nodes.map(\.index) == [0, 1])
        #expect(nodes.map(\.id) == [0, 1])
    }

    @Test func indicesAreContiguousAcrossLevels() {
        let nodes = OutlineBuilder.build([
            block(.listItem(indent: 0), "A"),
            block(.listItem(indent: 2), "a"),
            block(.listItem(indent: 0), "B"),
        ])
        #expect(nodes.map(\.index) == [0, 1, 2])
    }

    @Test func citationsAreCarried() {
        let c = ScriptureCitation(
            rawText: "x", bookCanonical: "psalms", chapter: 1, verseStart: 1,
            verseEnd: nil, displayShort: "Ps. 1:1"
        )
        let nodes = OutlineBuilder.build([Block(kind: .listItem(indent: 0), text: "A", citations: [c])])
        #expect(nodes[0].citations == [c])
    }
}
