//
//  ScriptureDetectorTests.swift
//  RecitoTests
//
//  Known book tokens hit (EN + ES); bare number pairs miss.
//

import Testing
import Foundation
@testable import Recito

struct ScriptureDetectorTests {

    @Test func detectsEnglishAbbreviation() {
        let hits = ScriptureDetector.detect(in: "See Ps. 37:7 for comfort.")
        #expect(hits.count == 1)
        #expect(hits[0].bookCanonical == "psalms")
        #expect(hits[0].chapter == 37)
        #expect(hits[0].verseStart == 7)
        #expect(hits[0].displayShort == "Ps. 37:7")
    }

    @Test func detectsSpanishName() {
        let hits = ScriptureDetector.detect(in: "Como dice Salmo 83:18 …")
        #expect(hits.count == 1)
        #expect(hits[0].bookCanonical == "psalms")
        #expect(hits[0].chapter == 83)
        #expect(hits[0].verseStart == 18)
        #expect(hits[0].displayShort == "Ps. 83:18")
    }

    @Test func detectsNumberedBook() {
        let hits = ScriptureDetector.detect(in: "Paul wrote in 2 Tim. 2:5 about endurance.")
        #expect(hits.count == 1)
        #expect(hits[0].bookCanonical == "2timothy")
        #expect(hits[0].displayShort == "2 Tim. 2:5")
    }

    @Test func detectsFullEnglishName() {
        let hits = ScriptureDetector.detect(in: "John 3:16 is well known.")
        #expect(hits.count == 1)
        #expect(hits[0].bookCanonical == "john")
    }

    @Test func detectsVerseRange() {
        let hits = ScriptureDetector.detect(in: "Read Ps. 37:7-9 slowly.")
        #expect(hits.count == 1)
        #expect(hits[0].verseStart == 7)
        #expect(hits[0].verseEnd == 9)
        #expect(hits[0].displayShort == "Ps. 37:7-9")
    }

    @Test func ignoresBareNumberPair() {
        // The teleprompter timer literally renders "12:30" — must NOT match.
        #expect(ScriptureDetector.detect(in: "The time is 12:30 now.").isEmpty)
        #expect(ScriptureDetector.detect(in: "Meeting at 9:45 sharp.").isEmpty)
    }

    @Test func ignoresUnknownWordBeforeNumbers() {
        #expect(ScriptureDetector.detect(in: "Section 4:2 of the manual.").isEmpty)
    }

    @Test func ignoresLowercaseCommonWordsThatCollideWithAbbreviations() {
        // "is"→Isaiah, "am"→Amos: must not match when written as normal words.
        #expect(ScriptureDetector.detect(in: "The time is 12:30 now.").isEmpty)
        #expect(ScriptureDetector.detect(in: "Here i am 5:2 ready.").isEmpty)
    }

    @Test func capitalizedShortAbbreviationStillDetects() {
        // A real, capitalized abbreviation should still resolve.
        let hits = ScriptureDetector.detect(in: "Is. 40:31 gives strength.")
        #expect(hits.first?.bookCanonical == "isaiah")
    }

    @Test func detectsMultipleInOneString() {
        let hits = ScriptureDetector.detect(in: "Compare Juan 3:16 with Romanos 5:8.")
        #expect(hits.count == 2)
        #expect(hits[0].bookCanonical == "john")
        #expect(hits[1].bookCanonical == "romans")
    }

    @Test func markdownLinkMarksCitationActiveWithURL() {
        let raw = "As [Ps. 37:7](https://www.jw.org/finder?bible=19037007) reminds us."
        let hits = ScriptureDetector.detect(inRaw: raw)
        #expect(hits.count == 1)
        #expect(hits[0].bookCanonical == "psalms")
        #expect(hits[0].isLinked == true)
        #expect(hits[0].url?.absoluteString.contains("19037007") == true)
    }

    @Test func bareMentionIsDetectedButInactive() {
        let hits = ScriptureDetector.detect(inRaw: "We just mention Ps. 37:7 here.")
        #expect(hits.count == 1)
        #expect(hits[0].isLinked == false)
        #expect(hits[0].url == nil)
    }

    @Test func stripLinksReducesToLabel() {
        let clean = ScriptureDetector.stripLinks("See [Ps. 37:7](https://example.com/x) now.")
        #expect(clean == "See Ps. 37:7 now.")
    }
}
