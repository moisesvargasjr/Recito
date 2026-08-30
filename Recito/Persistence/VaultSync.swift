//
//  VaultSync.swift
//  Recito
//
//  Folds the files found in the linked vault folder into the library.
//
//  The file on disk is the source of truth for a vault talk's text and title;
//  Recito owns only what the file cannot express — the time limit, the reading
//  mode, when it was last opened, whether it is hidden. Those survive a refresh.
//

import Foundation

enum VaultSync {

    struct Result: Equatable {
        var talks: [Talk]
        var added: Int
        var updated: Int
        var removed: Int

        var changed: Bool { added > 0 || updated > 0 || removed > 0 }
    }

    /// Merge a folder scan into `talks`, returning the new library.
    ///
    /// Local talks pass through untouched. Vault talks are matched by relative
    /// path: readable → refreshed in place, present but unreadable → left alone,
    /// absent → dropped (the vault is the source of truth, so a deleted file
    /// means a deleted talk).
    static func merge(
        scan: VaultScan,
        into talks: [Talk],
        defaultTimeLimit: TimeInterval
    ) -> Result {
        let byPath = Dictionary(
            scan.files.map { ($0.relativePath, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        var result: [Talk] = []
        var seen: Set<String> = []
        var updated = 0
        var removed = 0

        for talk in talks {
            guard let path = talk.source.relativePath else {
                result.append(talk)   // local talk — not ours to touch
                continue
            }
            guard let file = byPath[path] else {
                if scan.presentPaths.contains(path) {
                    seen.insert(path)   // still there, just not readable right now
                    result.append(talk)
                } else {
                    removed += 1        // genuinely gone from the vault
                }
                continue
            }
            seen.insert(path)

            var refreshed = talk
            refreshed.sourceText = file.text
            refreshed.title = title(for: file)
            if refreshed != talk { updated += 1 }
            result.append(refreshed)
        }

        let new = scan.files
            .filter { !seen.contains($0.relativePath) }
            .map { makeTalk(from: $0, defaultTimeLimit: defaultTimeLimit) }

        return Result(
            talks: result + new,
            added: new.count,
            updated: updated,
            removed: removed
        )
    }

    // MARK: - Building

    private static func makeTalk(from file: VaultFile, defaultTimeLimit: TimeInterval) -> Talk {
        // A newly discovered talk is stamped with the file's modification date
        // rather than "now", so the library orders vault talks by when they were
        // last worked on — the one just edited in Obsidian sorts to the front.
        Talk(
            title: title(for: file),
            sourceText: file.text,
            preferredMode: ImportViewModel.detectMode(from: file.text),
            timeLimit: defaultTimeLimit,
            createdAt: file.modifiedAt,
            lastOpenedAt: file.modifiedAt,
            source: .vault(relativePath: file.relativePath)
        )
    }

    /// The note's first heading, else its filename.
    static func title(for file: VaultFile) -> String {
        if let heading = MarkdownParser.headingTitle(from: file.text), !heading.isEmpty {
            return heading
        }
        return fileStem(of: file.relativePath)
    }

    private static func fileStem(of relativePath: String) -> String {
        let name = (relativePath as NSString).lastPathComponent
        let stem = (name as NSString).deletingPathExtension
        return stem.isEmpty ? name : stem
    }
}
