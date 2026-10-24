//
//  JSONTalkStore.swift
//  Recito
//
//  TalkPersistence backed by a single JSON file in Application Support. Writes
//  are atomic and off the main thread. Tiny data set (a few dozen talks), so the
//  whole library lives in memory and is rewritten on each mutation.
//

import Foundation

struct JSONTalkPersistence: TalkPersistence {
    private let fileURL: URL
    /// One serial queue for every instance, so `flush()` orders after all writes.
    private static let writeQueue = DispatchQueue(label: "com.moisesvargas.Recito.talkstore.write")

    init(filename: String = "talks.json") {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.init(directory: dir, filename: filename)
    }

    /// Store the library in `directory` (created if missing) — used by tests and
    /// the UI-test environment to keep data out of Application Support.
    init(directory: URL, filename: String = "talks.json") {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        fileURL = directory.appendingPathComponent(filename)
    }

    func load() -> [Talk] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Talk].self, from: data)) ?? []
    }

    func save(_ talks: [Talk]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(talks) else { return }
        let url = fileURL
        Self.writeQueue.async {
            try? data.write(to: url, options: .atomic)
        }
    }

    /// Block until every queued write has landed on disk (for tests).
    func flush() {
        Self.writeQueue.sync {}
    }
}
