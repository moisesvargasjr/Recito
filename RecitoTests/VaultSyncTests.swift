//
//  VaultSyncTests.swift
//  RecitoTests
//
//  Folding a linked folder into the library: the file owns the text and title,
//  Recito owns everything the file cannot express.
//

import Foundation
import Testing
@testable import Recito

struct VaultSyncTests {

    private func file(
        _ path: String,
        _ text: String,
        modified: Date = Date(timeIntervalSince1970: 1_700_000_000)
    ) -> VaultFile {
        VaultFile(relativePath: path, text: text, modifiedAt: modified)
    }

    private let limit: TimeInterval = 30 * 60

    /// A scan where every listed file was read successfully.
    private func scan(_ files: [VaultFile], alsoPresent: [String] = []) -> VaultScan {
        VaultScan(
            files: files,
            presentPaths: Set(files.map(\.relativePath)).union(alsoPresent)
        )
    }

    // MARK: - Discovery

    @Test func newFileBecomesVaultTalkTitledByItsHeading() {
        let result = VaultSync.merge(
            scan: scan([file("012-autoridad.md", "# 12 — La autoridad\n\nBuenas tardes.")]),
            into: [],
            defaultTimeLimit: limit
        )
        #expect(result.added == 1)
        #expect(result.talks.count == 1)
        #expect(result.talks[0].title == "12 — La autoridad")
        #expect(result.talks[0].source == .vault(relativePath: "012-autoridad.md"))
    }

    @Test func titleFallsBackToFilenameWhenThereIsNoHeading() {
        // "Discurso 5 Min.md" opens straight into prose — the filename makes a
        // far better card than a truncated first sentence.
        let result = VaultSync.merge(
            scan: scan([file("Discurso 5 Min.md", "Hay un dicho que escuché en inglés y se me grabó.")]),
            into: [],
            defaultTimeLimit: limit
        )
        #expect(result.talks[0].title == "Discurso 5 Min")
    }

    @Test func newTalkIsStampedWithTheFileModificationDate() {
        let when = Date(timeIntervalSince1970: 1_600_000_000)
        let result = VaultSync.merge(
            scan: scan([file("a.md", "# A\n\nx", modified: when)]),
            into: [],
            defaultTimeLimit: limit
        )
        #expect(result.talks[0].lastOpenedAt == when)
        #expect(result.talks[0].createdAt == when)
    }

    // MARK: - Refresh

    @Test func editedFileRefreshesTextButKeepsRecitoOwnedState() {
        let existing = Talk(
            title: "Old title",
            sourceText: "# Old title\n\nold body",
            preferredMode: .outline,
            timeLimit: 8 * 60,
            createdAt: Date(timeIntervalSince1970: 1),
            lastOpenedAt: Date(timeIntervalSince1970: 99),
            source: .vault(relativePath: "talk.md"),
            isHidden: true
        )
        let result = VaultSync.merge(
            scan: scan([file("talk.md", "# New title\n\nnew body")]),
            into: [existing],
            defaultTimeLimit: limit
        )

        #expect(result.updated == 1)
        #expect(result.talks.count == 1)
        let talk = result.talks[0]
        // The vault owns these.
        #expect(talk.title == "New title")
        #expect(talk.sourceText.contains("new body"))
        // Recito owns these.
        #expect(talk.id == existing.id)
        #expect(talk.timeLimit == 8 * 60)
        #expect(talk.preferredMode == .outline)
        #expect(talk.lastOpenedAt == Date(timeIntervalSince1970: 99))
        #expect(talk.isHidden)
    }

    @Test func unchangedFileReportsNoChange() {
        let source = "# Same\n\nbody"
        let existing = Talk(
            title: "Same",
            sourceText: source,
            source: .vault(relativePath: "talk.md")
        )
        let result = VaultSync.merge(
            scan: scan([file("talk.md", source)]),
            into: [existing],
            defaultTimeLimit: limit
        )
        #expect(!result.changed)
        #expect(result.updated == 0)
    }

    // MARK: - Removal and isolation

    @Test func fileDeletedFromVaultDropsItsTalk() {
        let existing = Talk(title: "Gone", sourceText: "x", source: .vault(relativePath: "gone.md"))
        let result = VaultSync.merge(scan: scan([]), into: [existing], defaultTimeLimit: limit)
        #expect(result.removed == 1)
        #expect(result.talks.isEmpty)
    }

    @Test func localTalksAreNeverTouchedByASync() {
        let local = Talk(title: "Pasted", sourceText: "typed here", source: .local)
        let result = VaultSync.merge(
            scan: scan([file("new.md", "# New\n\nbody")]),
            into: [local],
            defaultTimeLimit: limit
        )
        #expect(result.removed == 0)
        #expect(result.talks.contains(local))
        #expect(result.talks.count == 2)
    }

    @Test func aTalkIsMatchedByPathNotByTitle() {
        // Two notes can share a heading; identity is the file path.
        let existing = Talk(
            title: "Repeated",
            sourceText: "# Repeated\n\none",
            source: .vault(relativePath: "one.md")
        )
        let result = VaultSync.merge(
            scan: scan([
                file("one.md", "# Repeated\n\none"),
                file("two.md", "# Repeated\n\ntwo")
            ]),
            into: [existing],
            defaultTimeLimit: limit
        )
        #expect(result.added == 1)
        #expect(result.talks.count == 2)
        #expect(result.talks.first { $0.source.relativePath == "one.md" }?.id == existing.id)
    }

    @Test func aFileThatIsPresentButUnreadableKeepsItsTalkIntact() {
        // Obsidian Sync can be mid-write when the app comes forward. That must
        // not read as a deletion: re-adding later would mint a new id and reset
        // the time limit and reading mode the speaker had set.
        let existing = Talk(
            title: "Mid-sync",
            sourceText: "# Mid-sync\n\nbody",
            preferredMode: .outline,
            timeLimit: 6 * 60,
            source: .vault(relativePath: "talk.md")
        )
        let result = VaultSync.merge(
            scan: VaultScan(files: [], presentPaths: ["talk.md"]),
            into: [existing],
            defaultTimeLimit: limit
        )
        #expect(result.removed == 0)
        #expect(!result.changed)
        #expect(result.talks == [existing])
        #expect(result.talks[0].timeLimit == 6 * 60)
    }
}
