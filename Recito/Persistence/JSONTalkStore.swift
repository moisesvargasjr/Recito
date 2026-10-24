//
//  JSONTalkStore.swift
//  Recito
//
//  TalkPersistence backed by a single JSON file in Application Support. Writes
//  are atomic and off the main thread. Tiny data set (a few dozen talks), so the
//  whole library lives in memory and is rewritten on each mutation.
//

import Foundation
import os

struct JSONTalkPersistence: TalkPersistence {
    private let fileURL: URL
    /// One serial queue for every instance, so `flush()` orders after all writes.
    private static let writeQueue = DispatchQueue(label: "com.moisesvargas.Recito.talkstore.write")
    private static let log = Logger(subsystem: "com.moisesvargas.Recito", category: "persistence")

    init(filename: String = "talks.json") {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.init(directory: dir, filename: filename)
    }

    /// Store the library in `directory` (created if missing) — used by tests and
    /// the UI-test environment to keep data out of Application Support.
    init(directory: URL, filename: String = "talks.json") {
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            Self.log.error("Could not create talk directory: \(error.localizedDescription, privacy: .public)")
        }
        fileURL = directory.appendingPathComponent(filename)
    }

    func load() -> [Talk] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([Talk].self, from: data)
        } catch {
            Self.log.error("Could not read talk library: \(error.localizedDescription, privacy: .public)")
            preserveUnreadableFile()
            return []
        }
    }

    func save(_ talks: [Talk]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data: Data
        do {
            data = try encoder.encode(talks)
        } catch {
            Self.log.error("Could not encode talk library: \(error.localizedDescription, privacy: .public)")
            return
        }
        let url = fileURL
        let log = Self.log
        Self.writeQueue.async {
            do {
                try data.write(to: url, options: .atomic)
            } catch {
                log.error("Could not write talk library: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    /// Block until every queued write has landed on disk (for tests). Never call
    /// from inside a write-queue block.
    func flush() {
        Self.writeQueue.sync {}
    }

    /// Keep an unreadable library as `<file>.corrupt` so the next save — which
    /// rewrites the file from the (now empty) in-memory list — can't destroy it.
    private func preserveUnreadableFile() {
        let backup = fileURL.appendingPathExtension("corrupt")
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: backup.path) { try fm.removeItem(at: backup) }
            try fm.moveItem(at: fileURL, to: backup)
        } catch {
            Self.log.error("Could not preserve unreadable library: \(error.localizedDescription, privacy: .public)")
        }
    }
}
