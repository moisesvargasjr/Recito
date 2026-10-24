//
//  VaultViewModelTests.swift
//  RecitoTests
//
//  The folder read happens on a background queue; tests await the published
//  status instead of sleeping.
//

import Testing
import Foundation
import Combine
@testable import Recito

@MainActor
struct VaultViewModelTests {
    @MainActor
    private struct Fixture {
        let iso = IsolatedDefaults()
        let dir = TempDir()
        let persistence: InMemoryPersistence
        let store: TalkStore

        init(talks: [Talk] = []) {
            let persistence = InMemoryPersistence(talks)
            self.persistence = persistence
            store = TalkStore(persistence: persistence, vault: VaultFolder(defaults: iso.defaults))
        }

        func write(_ text: String, to name: String) throws {
            try Data(text.utf8).write(to: dir.url.appendingPathComponent(name))
        }

        func tearDown() { iso.tearDown(); dir.tearDown() }
    }

    /// Wait for the first status that is neither idle nor refreshing.
    private func settled(_ vm: VaultViewModel) async -> VaultViewModel.Status {
        for await status in vm.$status.values {
            switch status {
            case .idle, .refreshing: continue
            default: return status
            }
        }
        return .idle
    }

    @Test func startsIdleAndNotNeedingRelink() {
        let vm = VaultViewModel()
        #expect(vm.status == .idle)
        #expect(!vm.needsRelink)
        #expect(!vm.pickerPresented)
    }

    @Test func refreshWhileUnlinkedIsANoOp() {
        let f = Fixture()
        defer { f.tearDown() }
        let vm = VaultViewModel()
        vm.refresh(store: f.store, defaultTimeLimit: 600)
        #expect(vm.status == .idle)
        #expect(f.persistence.saveCount == 0)
    }

    @Test(.timeLimit(.minutes(1)))
    func linkImportsTheFolderAndReportsCounts() async throws {
        let f = Fixture()
        defer { f.tearDown() }
        try f.write("# First\n\nHello", to: "first.md")
        try f.write("# Second\n\nWorld", to: "second.md")
        let vm = VaultViewModel()

        vm.link(to: f.dir.url, store: f.store, defaultTimeLimit: 420)
        let status = await settled(vm)

        #expect(status == .synced(added: 2, updated: 0, removed: 0))
        #expect(f.store.talks.count == 2)
        #expect(f.store.talks.allSatisfy { $0.source.isVault && $0.timeLimit == 420 })
        #expect(f.persistence.saveCount == 1)
        #expect(!vm.needsRelink)
    }

    @Test(.timeLimit(.minutes(1)))
    func refreshWithNoChangesDoesNotRewriteTheLibrary() async throws {
        let f = Fixture()
        defer { f.tearDown() }
        try f.write("# One\n\nBody", to: "one.md")
        let vm = VaultViewModel()
        vm.link(to: f.dir.url, store: f.store, defaultTimeLimit: 600)
        _ = await settled(vm)
        let saves = f.persistence.saveCount

        vm.refresh(store: f.store, defaultTimeLimit: 600)
        #expect(vm.status == .refreshing)
        let status = await settled(vm)

        #expect(status == .synced(added: 0, updated: 0, removed: 0))
        #expect(f.persistence.saveCount == saves)
    }

    @Test(.timeLimit(.minutes(1)))
    func refreshPicksUpEditsAndDeletions() async throws {
        let f = Fixture()
        defer { f.tearDown() }
        try f.write("# One\n\nBody", to: "one.md")
        try f.write("# Two\n\nBody", to: "two.md")
        let vm = VaultViewModel()
        vm.link(to: f.dir.url, store: f.store, defaultTimeLimit: 600)
        _ = await settled(vm)

        try f.write("# One\n\nEdited body", to: "one.md")
        try FileManager.default.removeItem(at: f.dir.url.appendingPathComponent("two.md"))
        try f.write("# Three\n\nNew", to: "three.md")
        vm.refresh(store: f.store, defaultTimeLimit: 600)

        // The status object does not change between identical outcomes, so
        // wait for the refresh to flip back out of .refreshing.
        let status = await settled(vm)
        #expect(status == .synced(added: 1, updated: 1, removed: 1))
        #expect(Set(f.store.talks.compactMap(\.source.relativePath)) == ["one.md", "three.md"])
    }

    @Test func linkFailureSurfacesTheError() {
        let f = Fixture()
        defer { f.tearDown() }
        let vm = VaultViewModel()
        vm.link(to: f.dir.url.appendingPathComponent("missing"), store: f.store, defaultTimeLimit: 600)
        guard case .failed(let message) = vm.status else {
            Issue.record("expected failed, got \(vm.status)")
            return
        }
        #expect(!message.isEmpty)
        #expect(!f.store.vault.isLinked)
    }

    @Test(.timeLimit(.minutes(1)))
    func brokenBookmarkRequestsRelink() async {
        let f = Fixture()
        defer { f.tearDown() }
        f.iso.defaults.set(Data([9, 9, 9]), forKey: "recito.vault.bookmark")
        let vm = VaultViewModel()

        vm.refresh(store: f.store, defaultTimeLimit: 600)
        let status = await settled(vm)

        guard case .failed = status else {
            Issue.record("expected failed, got \(status)")
            return
        }
        #expect(vm.needsRelink)
    }

    @Test(.timeLimit(.minutes(1)))
    func successfulLinkClearsNeedsRelink() async throws {
        let f = Fixture()
        defer { f.tearDown() }
        f.iso.defaults.set(Data([9, 9, 9]), forKey: "recito.vault.bookmark")
        let vm = VaultViewModel()
        vm.refresh(store: f.store, defaultTimeLimit: 600)
        _ = await settled(vm)
        #expect(vm.needsRelink)

        try f.write("# Back\n\nOn", to: "back.md")
        vm.link(to: f.dir.url, store: f.store, defaultTimeLimit: 600)
        #expect(!vm.needsRelink)
        let status = await settled(vm)
        #expect(status == .synced(added: 1, updated: 0, removed: 0))
    }

    @Test(.timeLimit(.minutes(1)))
    func unlinkDropsVaultTalksButKeepsLocalOnes() async throws {
        let local = TalkFactory.talk(title: "Mine")
        let f = Fixture(talks: [local])
        defer { f.tearDown() }
        try f.write("# Vault\n\nBody", to: "v.md")
        let vm = VaultViewModel()
        vm.link(to: f.dir.url, store: f.store, defaultTimeLimit: 600)
        _ = await settled(vm)
        #expect(f.store.talks.count == 2)

        vm.unlink(store: f.store)

        #expect(f.store.talks == [local])
        #expect(!f.store.vault.isLinked)
        #expect(vm.status == .idle)
        #expect(!vm.needsRelink)
    }

    @Test func statusEquatableDistinguishesCases() {
        #expect(VaultViewModel.Status.failed("a") != .failed("b"))
        #expect(VaultViewModel.Status.synced(added: 1, updated: 0, removed: 0) != .synced(added: 0, updated: 0, removed: 0))
        #expect(VaultViewModel.Status.idle != .refreshing)
    }
}
