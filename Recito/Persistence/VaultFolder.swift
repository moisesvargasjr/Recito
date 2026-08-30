//
//  VaultFolder.swift
//  Recito
//
//  Access to a user-picked folder of Markdown talks — in practice a folder
//  inside an Obsidian vault, which syncs onto the device on its own. The folder
//  is chosen once; a security-scoped bookmark makes that choice survive relaunch.
//
//  Read-only by design. Recito never writes into the vault: the file on disk
//  stays the single source of truth and Obsidian remains the only editor.
//

import Foundation

/// One Markdown file found in the linked folder.
struct VaultFile: Equatable {
    /// Path relative to the linked folder — the stable identity across syncs.
    let relativePath: String
    let text: String
    let modifiedAt: Date
}

/// The outcome of one pass over the linked folder.
struct VaultScan: Equatable {
    /// Files that were read successfully.
    let files: [VaultFile]
    /// Every Markdown file *seen*, readable or not.
    ///
    /// A note can exist but fail to read for a moment — Obsidian Sync writing
    /// it, an encoding we can't decode. Without this, an unreadable file is
    /// indistinguishable from a deleted one, and the refresh would drop the
    /// talk and re-add it with a new identity, losing its time limit and mode.
    let presentPaths: Set<String>
}

enum VaultFolderError: LocalizedError {
    /// No folder has been linked yet.
    case notLinked
    /// The bookmark no longer resolves — most often Obsidian was reinstalled,
    /// which changes its container path. Recoverable by picking the folder again.
    case linkBroken
    case unreadable(String)

    var errorDescription: String? {
        switch self {
        case .notLinked:
            return "No vault folder is linked yet."
        case .linkBroken:
            return "Recito lost access to the linked folder. Pick it again to reconnect."
        case .unreadable(let detail):
            return "Could not read the vault folder: \(detail)"
        }
    }
}

/// Stores the folder choice and reads Markdown out of it.
final class VaultFolder {
    private let defaults: UserDefaults
    private let bookmarkKey = "recito.vault.bookmark"
    private let nameKey = "recito.vault.displayName"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: - The link

    var isLinked: Bool { defaults.data(forKey: bookmarkKey) != nil }

    /// Folder name shown in the UI, e.g. "talks".
    var displayName: String? { defaults.string(forKey: nameKey) }

    /// Record the folder the user picked. The URL comes from a document picker
    /// and is already security-scoped.
    func link(to url: URL) throws {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let bookmark = try url.bookmarkData(
                options: [],
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            defaults.set(bookmark, forKey: bookmarkKey)
            defaults.set(url.lastPathComponent, forKey: nameKey)
        } catch {
            throw VaultFolderError.unreadable(error.localizedDescription)
        }
    }

    func unlink() {
        defaults.removeObject(forKey: bookmarkKey)
        defaults.removeObject(forKey: nameKey)
    }

    // MARK: - Reading

    /// Every Markdown file in the folder, recursively, sorted by path.
    ///
    /// Reads are best-effort per file: one unreadable note is skipped rather
    /// than failing the whole refresh — but it is still reported as present, so
    /// the merge keeps its talk instead of treating it as deleted.
    func scan() throws -> VaultScan {
        guard let bookmark = defaults.data(forKey: bookmarkKey) else {
            throw VaultFolderError.notLinked
        }

        var isStale = false
        guard let root = try? URL(
            resolvingBookmarkData: bookmark,
            options: [],
            relativeTo: nil,
            bookmarkDataIsStale: &isStale
        ) else {
            throw VaultFolderError.linkBroken
        }

        guard root.startAccessingSecurityScopedResource() else {
            throw VaultFolderError.linkBroken
        }
        defer { root.stopAccessingSecurityScopedResource() }

        // A stale bookmark still resolved, so refresh it while access is held.
        if isStale, let renewed = try? root.bookmarkData(
            options: [],
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        ) {
            defaults.set(renewed, forKey: bookmarkKey)
        }

        let keys: [URLResourceKey] = [.isRegularFileKey, .contentModificationDateKey]
        guard let walker = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw VaultFolderError.unreadable("folder could not be enumerated")
        }

        let rootPath = root.standardizedFileURL.path
        var files: [VaultFile] = []
        var present: Set<String> = []

        for case let url as URL in walker {
            guard url.pathExtension.lowercased() == "md" else { continue }
            guard let values = try? url.resourceValues(forKeys: Set(keys)),
                  values.isRegularFile == true else { continue }

            let path = url.standardizedFileURL.path
            let relative = path.hasPrefix(rootPath + "/")
                ? String(path.dropFirst(rootPath.count + 1))
                : url.lastPathComponent
            present.insert(relative)

            guard let text = readText(at: url) else { continue }
            files.append(
                VaultFile(
                    relativePath: relative,
                    text: text,
                    modifiedAt: values.contentModificationDate ?? .distantPast
                )
            )
        }

        return VaultScan(
            files: files.sorted { $0.relativePath < $1.relativePath },
            presentPaths: present
        )
    }

    private func readText(at url: URL) -> String? {
        if let text = try? String(contentsOf: url, encoding: .utf8) { return text }
        guard let data = try? Data(contentsOf: url) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
