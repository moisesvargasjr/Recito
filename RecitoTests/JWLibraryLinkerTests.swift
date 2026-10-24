//
//  JWLibraryLinkerTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

struct JWLibraryLinkerTests {
    private func citation(_ book: String, _ chapter: Int, _ verse: Int) -> ScriptureCitation {
        ScriptureCitation(
            rawText: "x", bookCanonical: book, chapter: chapter, verseStart: verse,
            verseEnd: nil, displayShort: "x"
        )
    }

    private func query(_ url: URL) -> [String: String] {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    @Test func buildsAFinderLinkWithTheBibleCode() throws {
        let url = try #require(JWLibraryLinker().url(for: citation("psalms", 37, 7)))
        #expect(url.host == "www.jw.org")
        #expect(url.path == "/finder")
        let q = query(url)
        #expect(q["bible"] == "19037007")
        #expect(q["wtlocale"] == "S")
        #expect(q["pub"] == "nwtsty")
        #expect(q["prefer"] == "lang")
    }

    @Test func localeIsConfigurable() throws {
        let url = try #require(JWLibraryLinker(localeCode: "E").url(for: citation("genesis", 1, 1)))
        #expect(query(url)["wtlocale"] == "E")
        #expect(query(url)["bible"] == "01001001")
    }

    @Test func unknownBookHasNoLink() {
        #expect(JWLibraryLinker().url(for: citation("narnia", 1, 1)) == nil)
    }

    @Test func largeChapterAndVersePadToThreeDigits() throws {
        let url = try #require(JWLibraryLinker().url(for: citation("psalms", 119, 176)))
        #expect(query(url)["bible"] == "19119176")
    }
}

struct BibleBookCatalogTests {
    @Test func hasSixtySixBooksWithUniqueKeys() {
        #expect(BibleBookCatalog.books.count == 66)
        #expect(Set(BibleBookCatalog.books.map(\.canonical)).count == 66)
    }

    @Test func bookNumbersFollowListOrder() {
        #expect(BibleBookCatalog.bookNumber(for: "genesis") == 1)
        #expect(BibleBookCatalog.bookNumber(for: "psalms") == 19)
        #expect(BibleBookCatalog.bookNumber(for: "revelation") == 66)
        #expect(BibleBookCatalog.bookNumber(for: "nope") == nil)
    }

    @Test func normalizeFoldsCaseAccentsDotsAndWhitespace() {
        #expect(BibleBookCatalog.normalize("  Génesis ") == "genesis")
        #expect(BibleBookCatalog.normalize("2  Tim.") == "2 tim")
        #expect(BibleBookCatalog.normalize("Sal.") == "sal")
        #expect(BibleBookCatalog.normalize("") == "")
    }

    @Test func lookupResolvesEnglishAndSpanishNames() {
        #expect(BibleBookCatalog.normalizedLookup["salmo"]?.canonical == "psalms")
        #expect(BibleBookCatalog.normalizedLookup["psalms"]?.canonical == "psalms")
        #expect(BibleBookCatalog.normalizedLookup["apocalipsis"]?.canonical == "revelation")
        #expect(BibleBookCatalog.normalizedLookup["exodo"]?.canonical == "exodus")
        #expect(BibleBookCatalog.normalizedLookup["xyz"] == nil)
    }

    @Test func everyBookHasNamesAndALabel() {
        for book in BibleBookCatalog.books {
            #expect(!book.names.isEmpty, "\(book.canonical) has no names")
            #expect(!book.displayShort.isEmpty, "\(book.canonical) has no label")
        }
    }
}
