//
//  VaultFolderTests.swift
//  RecitoTests
//
//  Real temp directories + an isolated UserDefaults suite for the bookmark.
//

import Testing
import Foundation
@testable import Recito

struct VaultFolderTests {
    private struct Fixture {
        let iso = IsolatedDefaults()
        let dir = TempDir()
        var folder: VaultFolder { VaultFolder(defaults: iso.defaults) }

        func write(_ text: String, to relative: String) throws {
            let url = dir.url.appendingPathComponent(relative)
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try Data(text.utf8).write(to: url)
        }

        func tearDown() { iso.tearDown(); dir.tearDown() }
    }

    @Test func startsUnlinked() {
        let f = Fixture()
        defer { f.tearDown() }
        #expect(!f.folder.isLinked)
        #expect(f.folder.displayName == nil)
    }

    @Test func scanWhileUnlinkedThrowsNotLinked() {
        let f = Fixture()
        defer { f.tearDown() }
        #expect(throws: VaultFolderError.self) { try f.folder.scan() }
        do { _ = try f.folder.scan() } catch let error as VaultFolderError {
            if case .notLinked = error {} else { Issue.record("expected notLinked, got \(error)") }
        } catch { Issue.record("unexpected \(error)") }
    }

    @Test func linkRecordsBookmarkAndName() throws {
        let f = Fixture()
        defer { f.tearDown() }
        let folder = f.folder
        try folder.link(to: f.dir.url)
        #expect(folder.isLinked)
        #expect(folder.displayName == f.dir.url.lastPathComponent)
        // A second instance on the same defaults sees the link (survives relaunch).
        #expect(VaultFolder(defaults: f.iso.defaults).isLinked)
    }

    @Test func linkToMissingFolderFails() {
        let f = Fixture()
        defer { f.tearDown() }
        let folder = f.folder
        let missing = f.dir.url.appendingPathComponent("does-not-exist")
        #expect(throws: VaultFolderError.self) { try folder.link(to: missing) }
        #expect(!folder.isLinked)
    }

    @Test func unlinkClearsTheLink() throws {
        let f = Fixture()
        defer { f.tearDown() }
        let folder = f.folder
        try folder.link(to: f.dir.url)
        folder.unlink()
        #expect(!folder.isLinked)
        #expect(folder.displayName == nil)
    }

    @Test func scanFindsMarkdownRecursivelySorted() throws {
        let f = Fixture()
        defer { f.tearDown() }
        try f.write("b", to: "b.md")
        try f.write("a", to: "sub/a.MD")
        try f.write("skip", to: "notes.txt")
        try f.write("hidden", to: ".secret.md")
        let folder = f.folder
        try folder.link(to: f.dir.url)

        let scan = try folder.scan()
        #expect(scan.files.map(\.relativePath) == ["b.md", "sub/a.MD"])
        #expect(scan.files.map(\.text) == ["b", "a"])
        #expect(scan.presentPaths == ["b.md", "sub/a.MD"])
    }

    @Test func scanReportsModificationDates() throws {
        let f = Fixture()
        defer { f.tearDown() }
        try f.write("x", to: "x.md")
        let folder = f.folder
        try folder.link(to: f.dir.url)
        let file = try #require(try folder.scan().files.first)
        #expect(file.modifiedAt != .distantPast)
    }

    @Test func unreadableFileIsStillReportedPresent() throws {
        let f = Fixture()
        defer { f.tearDown() }
        try f.write("ok", to: "ok.md")
        let bad = f.dir.url.appendingPathComponent("bad.md")
        try Data([0xFF, 0xFE, 0xC0, 0xC1]).write(to: bad)
        let folder = f.folder
        try folder.link(to: f.dir.url)

        let scan = try folder.scan()
        #expect(scan.files.map(\.relativePath) == ["ok.md"])
        #expect(scan.presentPaths == ["bad.md", "ok.md"])
    }

    @Test func directoriesNamedLikeMarkdownAreIgnored() throws {
        let f = Fixture()
        defer { f.tearDown() }
        try FileManager.default.createDirectory(
            at: f.dir.url.appendingPathComponent("folder.md"), withIntermediateDirectories: true
        )
        let folder = f.folder
        try folder.link(to: f.dir.url)
        let scan = try folder.scan()
        #expect(scan.files.isEmpty)
        #expect(scan.presentPaths.isEmpty)
    }

    @Test func emptyFolderScansEmpty() throws {
        let f = Fixture()
        defer { f.tearDown() }
        let folder = f.folder
        try folder.link(to: f.dir.url)
        let scan = try folder.scan()
        #expect(scan == VaultScan(files: [], presentPaths: []))
    }

    @Test func deletedFolderBreaksTheLink() throws {
        let f = Fixture()
        defer { f.tearDown() }
        let folder = f.folder
        try folder.link(to: f.dir.url)
        f.dir.tearDown()
        do {
            _ = try folder.scan()
            Issue.record("expected a scan error")
        } catch let error as VaultFolderError {
            if case .linkBroken = error {} else { Issue.record("expected linkBroken, got \(error)") }
        } catch {
            Issue.record("unexpected \(error)")
        }
    }

    @Test func corruptBookmarkBreaksTheLink() {
        let f = Fixture()
        defer { f.tearDown() }
        f.iso.defaults.set(Data([1, 2, 3]), forKey: "recito.vault.bookmark")
        let folder = f.folder
        #expect(folder.isLinked)
        do {
            _ = try folder.scan()
            Issue.record("expected a scan error")
        } catch let error as VaultFolderError {
            if case .linkBroken = error {} else { Issue.record("expected linkBroken, got \(error)") }
        } catch {
            Issue.record("unexpected \(error)")
        }
    }

    @Test func errorsHaveUserFacingDescriptions() {
        #expect(VaultFolderError.notLinked.errorDescription?.contains("No vault folder") == true)
        #expect(VaultFolderError.linkBroken.errorDescription?.contains("Pick it again") == true)
        #expect(VaultFolderError.unreadable("boom").errorDescription?.contains("boom") == true)
    }
}
