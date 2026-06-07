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
    private let writeQueue = DispatchQueue(label: "com.moisesvargas.Recito.talkstore.write")

    init(filename: String = "talks.json") {
        let fm = FileManager.default
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent(filename)
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
        writeQueue.async {
            try? data.write(to: url, options: .atomic)
        }
    }
}
