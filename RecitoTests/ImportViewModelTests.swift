//
//  ImportViewModelTests.swift
//  RecitoTests
//

import Testing
import Foundation
@testable import Recito

@MainActor
struct ImportViewModelTests {
    // MARK: deriveTitle

    @Test func titleIsTheFirstNonEmptyLine() {
        #expect(ImportViewModel.deriveTitle(from: "\n\n  Hello world\nSecond") == "Hello world")
    }

    @Test func titleStripsHeadingAndListMarkers() {
        #expect(ImportViewModel.deriveTitle(from: "## My Talk\nbody") == "My Talk")
        #expect(ImportViewModel.deriveTitle(from: "- first point") == "first point")
        #expect(ImportViewModel.deriveTitle(from: "1. numbered") == "numbered")
    }

    @Test func titleIsCappedAtSixtyCharacters() {
        let title = ImportViewModel.deriveTitle(from: String(repeating: "a", count: 100))
        #expect(title.count == 60)
    }

    @Test func titleFallsBackWhenBlank() {
        #expect(ImportViewModel.deriveTitle(from: "") == "Untitled talk")
        #expect(ImportViewModel.deriveTitle(from: " \n\t\n  ") == "Untitled talk")
    }

    @Test func titleKeepsUnicode() {
        #expect(ImportViewModel.deriveTitle(from: "Esperanza para el futuro 🌅") == "Esperanza para el futuro 🌅")
    }

    // MARK: detectMode

    @Test func proseIsScript() {
        #expect(ImportViewModel.detectMode(from: "One.\n\nTwo.\n\nThree.") == .script)
    }

    @Test func dominantBulletsAreOutline() {
        #expect(ImportViewModel.detectMode(from: "Intro.\n\n- a\n- b\n- c") == .outline)
    }

    @Test func tieGoesToScript() {
        #expect(ImportViewModel.detectMode(from: "Intro.\n\n- a") == .script)
    }

    @Test func headingsAreNeutral() {
        #expect(ImportViewModel.detectMode(from: "# A\n\n# B\n\nProse paragraph.") == .script)
        #expect(ImportViewModel.detectMode(from: "# A\n\n- x\n- y") == .outline)
    }

    @Test func emptyTextIsScript() {
        #expect(ImportViewModel.detectMode(from: "") == .script)
    }

    // MARK: canAdd / makeTalk

    @Test func canAddRequiresNonBlankText() {
        let vm = ImportViewModel()
        #expect(!vm.canAdd)
        vm.pasteText = "  \n "
        #expect(!vm.canAdd)
        vm.pasteText = " hi "
        #expect(vm.canAdd)
    }

    @Test func makeTalkReturnsNilForBlankText() {
        let vm = ImportViewModel()
        vm.pasteText = "   "
        #expect(vm.makeTalk(defaultTimeLimit: 600, mode: .script) == nil)
    }

    @Test func makeTalkTrimsAndAppliesSettings() throws {
        let vm = ImportViewModel()
        vm.pasteText = "\n  # Title\n\nBody text  \n"
        let talk = try #require(vm.makeTalk(defaultTimeLimit: 900, mode: .outline))
        #expect(talk.title == "Title")
        #expect(talk.sourceText == "# Title\n\nBody text")
        #expect(talk.timeLimit == 900)
        #expect(talk.preferredMode == .outline)
        #expect(talk.source == .local)
        #expect(!talk.isHidden)
    }

    @Test func eachTalkGetsAFreshID() throws {
        let vm = ImportViewModel()
        vm.pasteText = "Same"
        let a = try #require(vm.makeTalk(defaultTimeLimit: 60, mode: .script))
        let b = try #require(vm.makeTalk(defaultTimeLimit: 60, mode: .script))
        #expect(a.id != b.id)
    }

    // MARK: loadFile

    private func write(_ data: Data, named name: String, in dir: TempDir) throws -> URL {
        let url = dir.url.appendingPathComponent(name)
        try data.write(to: url)
        return url
    }

    @Test func loadFileReadsUTF8Text() throws {
        let dir = TempDir()
        defer { dir.tearDown() }
        let url = try write(Data("Hola, ¿qué tal? 🙂".utf8), named: "talk.md", in: dir)
        let vm = ImportViewModel()
        vm.loadFile(at: url)
        #expect(vm.pasteText == "Hola, ¿qué tal? 🙂")
    }

    @Test func loadFileReplacesExistingText() throws {
        let dir = TempDir()
        defer { dir.tearDown() }
        let url = try write(Data("new".utf8), named: "a.txt", in: dir)
        let vm = ImportViewModel()
        vm.pasteText = "old"
        vm.loadFile(at: url)
        #expect(vm.pasteText == "new")
    }

    @Test func emptyFileLoadsAsEmptyText() throws {
        let dir = TempDir()
        defer { dir.tearDown() }
        let url = try write(Data(), named: "empty.md", in: dir)
        let vm = ImportViewModel()
        vm.pasteText = "keep?"
        vm.loadFile(at: url)
        #expect(vm.pasteText.isEmpty)
        #expect(!vm.canAdd)
    }

    @Test func unreadableFileLeavesTextUntouched() {
        let dir = TempDir()
        defer { dir.tearDown() }
        let vm = ImportViewModel()
        vm.pasteText = "keep"
        vm.loadFile(at: dir.url.appendingPathComponent("missing.md"))
        #expect(vm.pasteText == "keep")
    }

    @Test func nonUTF8FileLeavesTextUntouched() throws {
        let dir = TempDir()
        defer { dir.tearDown() }
        let url = try write(Data([0xFF, 0xFE, 0xFD, 0xC0]), named: "bin.md", in: dir)
        let vm = ImportViewModel()
        vm.pasteText = "keep"
        vm.loadFile(at: url)
        #expect(vm.pasteText == "keep")
    }

    @Test func directoryIsNotReadable() {
        let dir = TempDir()
        defer { dir.tearDown() }
        let vm = ImportViewModel()
        vm.pasteText = "keep"
        vm.loadFile(at: dir.url)
        #expect(vm.pasteText == "keep")
    }
}
