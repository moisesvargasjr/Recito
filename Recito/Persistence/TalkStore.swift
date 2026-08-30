//
//  TalkStore.swift
//  Recito
//
//  The in-memory library, observable by SwiftUI. The on-disk backend is hidden
//  behind `TalkPersistence` so it can be swapped (e.g. SwiftData) later without
//  touching call sites.
//

import Foundation
import Combine

protocol TalkPersistence {
    func load() -> [Talk]
    func save(_ talks: [Talk])
}

final class TalkStore: ObservableObject {
    @Published private(set) var talks: [Talk] = []

    private let persistence: TalkPersistence
    let vault: VaultFolder

    init(persistence: TalkPersistence, vault: VaultFolder = VaultFolder()) {
        self.persistence = persistence
        self.vault = vault
        self.talks = persistence.load()
    }

    func add(_ talk: Talk) {
        talks.insert(talk, at: 0)
        persist()
    }

    func update(_ talk: Talk) {
        guard let index = talks.firstIndex(where: { $0.id == talk.id }) else { return }
        talks[index] = talk
        persist()
    }

    func delete(_ talk: Talk) {
        talks.removeAll { $0.id == talk.id }
        persist()
    }

    func markOpened(_ id: Talk.ID) {
        guard let index = talks.firstIndex(where: { $0.id == id }) else { return }
        talks[index].lastOpenedAt = Date()
        persist()
    }

    func talk(with id: Talk.ID) -> Talk? {
        talks.first { $0.id == id }
    }

    /// Replace the whole library (used for first-run seeding).
    func seed(_ initial: [Talk]) {
        talks = initial
        persist()
    }

    func setHidden(_ hidden: Bool, for id: Talk.ID) {
        guard let index = talks.firstIndex(where: { $0.id == id }) else { return }
        talks[index].isHidden = hidden
        persist()
    }

    /// Adopt the result of a vault refresh.
    func applyVaultMerge(_ merged: [Talk]) {
        talks = merged
        persist()
    }

    private func persist() {
        persistence.save(talks)
    }
}

extension TalkStore {
    /// Production store backed by a JSON file, seeded with samples on first run.
    static func live() -> TalkStore {
        let store = TalkStore(persistence: JSONTalkPersistence(), vault: VaultFolder())
        store.seedSamplesIfFirstRun()
        return store
    }

    private static let didSeedKey = "recito.didSeedSamples"

    private func seedSamplesIfFirstRun() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.didSeedKey) else { return }
        if talks.isEmpty {
            seed(SampleTalks.all)
        }
        defaults.set(true, forKey: Self.didSeedKey)
    }
}
