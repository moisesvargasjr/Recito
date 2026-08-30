//
//  VaultViewModel.swift
//  Recito
//
//  Drives linking a vault folder and refreshing from it. The folder read runs
//  off the main thread; the merge and the store update come back to main, in
//  keeping with the app's no-custom-actors concurrency posture.
//

import Foundation
import Combine

@MainActor
final class VaultViewModel: ObservableObject {

    enum Status: Equatable {
        case idle
        case refreshing
        /// Last refresh succeeded. Counts describe what it changed.
        case synced(added: Int, updated: Int, removed: Int)
        case failed(String)
    }

    @Published private(set) var status: Status = .idle
    @Published var pickerPresented = false
    /// Set when the link breaks, so the UI can offer to re-pick the folder.
    @Published private(set) var needsRelink = false

    private let queue = DispatchQueue(label: "com.moisesvargas.Recito.vault.read")
    private var isRefreshing = false

    // MARK: - Linking

    func link(to url: URL, store: TalkStore, defaultTimeLimit: TimeInterval) {
        do {
            try store.vault.link(to: url)
            needsRelink = false
            refresh(store: store, defaultTimeLimit: defaultTimeLimit)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    func unlink(store: TalkStore) {
        store.vault.unlink()
        // Drop the mirrored talks; anything created in Recito stays.
        store.applyVaultMerge(store.talks.filter { !$0.source.isVault })
        status = .idle
        needsRelink = false
    }

    // MARK: - Refreshing

    /// Re-read the linked folder and fold it into the library. Safe to call on
    /// every foreground: it no-ops when nothing is linked or a read is in flight.
    func refresh(store: TalkStore, defaultTimeLimit: TimeInterval) {
        guard store.vault.isLinked, !isRefreshing else { return }
        isRefreshing = true
        status = .refreshing

        let vault = store.vault
        let existing = store.talks

        queue.async {
            let outcome: Swift.Result<VaultSync.Result, Error>
            do {
                let scan = try vault.scan()
                outcome = .success(
                    VaultSync.merge(
                        scan: scan,
                        into: existing,
                        defaultTimeLimit: defaultTimeLimit
                    )
                )
            } catch {
                outcome = .failure(error)
            }

            Task { @MainActor [weak self] in
                self?.finish(outcome, store: store)
            }
        }
    }

    private func finish(_ outcome: Swift.Result<VaultSync.Result, Error>, store: TalkStore) {
        isRefreshing = false
        switch outcome {
        case .success(let merged):
            // Only write when something actually moved, so a foreground with no
            // vault edits doesn't churn the JSON file.
            if merged.changed {
                store.applyVaultMerge(merged.talks)
            }
            needsRelink = false
            status = .synced(
                added: merged.added,
                updated: merged.updated,
                removed: merged.removed
            )
        case .failure(let error):
            if case .linkBroken? = error as? VaultFolderError {
                needsRelink = true
            }
            status = .failed(error.localizedDescription)
        }
    }
}
