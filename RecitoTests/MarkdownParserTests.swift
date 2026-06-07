//
//  MarkdownParserTests.swift
//  RecitoTests
//
//  One source → both reading models.
//

import Testing
@testable import Recito

struct MarkdownParserTests {

    @Test func proseBecomesParagraphSections() {
        let source = """
        Few qualities are tested as often as patience.

        We tend to think of patience as simply waiting.

        Real patience is active.
        """
        let doc = MarkdownParser.parse(source)
        #expect(doc.scriptSections.count == 3)
        #expect(doc.scriptSections[0].text == "Few qualities are tested as often as patience.")
        #expect(doc.scriptSections[2].text == "Real patience is active.")
        #expect(doc.scriptSections.map(\.index) == [0, 1, 2])
    }

    @Test func multiLineParagraphIsJoined() {
        let source = """
        Real patience is active.
        It is the steady choice to keep doing what is right.
        """
        let doc = MarkdownParser.parse(source)
        #expect(doc.scriptSections.count == 1)
        #expect(doc.scriptSections[0].text.contains("active. It is the steady"))
    }

    @Test func headingsAndBulletsBecomeOutline() {
        let source = """
        1. Open with the question everyone is really asking
        2. Patience is active, not passive waiting
           - The farmer who works the whole season
           - Ps. 37:7 — wait, but keep doing good
        3. What patience costs us
        """
        let doc = MarkdownParser.parse(source)
        let points = doc.outlineNodes.filter { $0.level == 0 }
        let subs = doc.outlineNodes.filter { $0.level == 1 }
        #expect(points.count == 3)
        #expect(subs.count == 2)
        #expect(points.map(\.number) == ["1", "2", "3"])
        #expect(subs.allSatisfy { $0.number == nil })
        #expect(doc.outlineNodes[1].text == "Patience is active, not passive waiting")
    }

    @Test func headingMarkersAreStripped() {
        let doc = MarkdownParser.parse("# The Value of Patience\n\nSome prose.")
        #expect(doc.outlineNodes.first?.text == "The Value of Patience")
        #expect(doc.outlineNodes.first?.level == 0)
    }

    @Test func pureProseFallsBackToOnePointPerParagraph() {
        let source = """
        First paragraph here.

        Second paragraph here.
        """
        let doc = MarkdownParser.parse(source)
        #expect(doc.outlineNodes.count == 2)
        #expect(doc.outlineNodes.allSatisfy { $0.level == 0 })
        #expect(doc.outlineNodes.map(\.number) == ["1", "2"])
    }

    @Test func headingsAreFlaggedInScriptSections() {
        let source = """
        # Opening

        Few qualities are tested as often as patience.

        ## The farmer

        Think of a farmer.
        """
        let doc = MarkdownParser.parse(source)
        let headings = doc.scriptSections.filter(\.isHeading)
        let prose = doc.scriptSections.filter { !$0.isHeading }
        #expect(headings.count == 2)
        #expect(headings.map(\.text) == ["Opening", "The farmer"])
        #expect(prose.count == 2)
        #expect(prose.allSatisfy { !$0.isHeading })
    }

    @Test func citationsAreCollectedInOrder() {
        let source = """
        As we read in Ps. 37:7, patience pays.

        Paul reminded us in 2 Tim. 2:5.
        """
        let doc = MarkdownParser.parse(source)
        #expect(doc.allCitations.count == 2)
        #expect(doc.allCitations[0].citation.bookCanonical == "psalms")
        #expect(doc.allCitations[0].sectionIndex == 0)
        #expect(doc.allCitations[1].citation.bookCanonical == "2timothy")
        #expect(doc.allCitations[1].sectionIndex == 1)
    }
}
