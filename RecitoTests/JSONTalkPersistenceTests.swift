//
//  JSONTalkPersistenceTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct JSONTalkPersistenceTests {
    private func persistence(in dir: TempDir, filename: String = "talks.json") -> JSONTalkPersistence {
        JSONTalkPersistence(directory: dir.url, filename: filename)
    }

    @Test func missingFileLoadsEmpty() {
        let dir = TempDir(); defer { dir.tearDown() }
        #expect(persistence(in: dir).load().isEmpty)
    }

    @Test func roundTripsTalksIncludingVaultSource() {
        let dir = TempDir(); defer { dir.tearDown() }
        let talks = [
            TalkFactory.talk(title: "Local"),
            TalkFactory.talk(title: "Vault", source: .vault(relativePath: "talks/012.md"), isHidden: true),
        ]
        let store = persistence(in: dir)
        store.save(talks)
        store.flush()
        #expect(persistence(in: dir).load() == talks)
    }

    @Test func laterSaveReplacesEarlier() {
        let dir = TempDir(); defer { dir.tearDown() }
        let store = persistence(in: dir)
        store.save([TalkFactory.talk(title: "One")])
        store.save([TalkFactory.talk(title: "Two")])
        store.flush()
        #expect(store.load().map(\.title) == ["Two"])
    }

    @Test func corruptFileLoadsEmptyInsteadOfCrashing() throws {
        let dir = TempDir(); defer { dir.tearDown() }
        try Data("not json".utf8).write(to: dir.url.appendingPathComponent("talks.json"))
        #expect(persistence(in: dir).load().isEmpty)
    }

    @Test func corruptFileIsPreservedBeforeTheNextSaveOverwritesIt() throws {
        let dir = TempDir(); defer { dir.tearDown() }
        let original = Data("not json".utf8)
        try original.write(to: dir.url.appendingPathComponent("talks.json"))
        let store = persistence(in: dir)
        _ = store.load()
        store.save([TalkFactory.talk(title: "New")])
        store.flush()
        let backup = dir.url.appendingPathComponent("talks.json.corrupt")
        #expect(try Data(contentsOf: backup) == original)
        #expect(store.load().map(\.title) == ["New"])
    }

    @Test func createsMissingDirectory() {
        let dir = TempDir(); defer { dir.tearDown() }
        let nested = dir.url.appendingPathComponent("a/b", isDirectory: true)
        let store = JSONTalkPersistence(directory: nested, filename: "talks.json")
        store.save([TalkFactory.talk()])
        store.flush()
        #expect(store.load().count == 1)
    }

    @Test func filenamesAreIndependent() {
        let dir = TempDir(); defer { dir.tearDown() }
        let a = persistence(in: dir, filename: "a.json")
        let b = persistence(in: dir, filename: "b.json")
        a.save([TalkFactory.talk(title: "A")])
        a.flush()
        #expect(b.load().isEmpty)
        #expect(a.load().map(\.title) == ["A"])
    }

    @Test func preservesUnicodeAndSpecialCharacters() {
        let dir = TempDir(); defer { dir.tearDown() }
        let text = "Ñandú 🎤 \"quoted\" ' OR 1=1; -- \\ \n\n  日本語"
        let store = persistence(in: dir)
        store.save([TalkFactory.talk(title: "Ünïcode ✓", text: text)])
        store.flush()
        let loaded = store.load()
        #expect(loaded.first?.title == "Ünïcode ✓")
        #expect(loaded.first?.sourceText == text)
    }

    @Test func savesAnEmptyLibrary() {
        let dir = TempDir(); defer { dir.tearDown() }
        let store = persistence(in: dir)
        store.save([TalkFactory.talk()])
        store.save([])
        store.flush()
        #expect(store.load().isEmpty)
    }
}
