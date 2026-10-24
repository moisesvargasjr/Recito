//
//  TempDir.swift
//  RecitoTests
//
//  A unique temporary directory, removed on tearDown.
//

import Foundation

struct TempDir {
    let url: URL

    init() {
        url = FileManager.default.temporaryDirectory
            .appendingPathComponent("recito-tests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    func tearDown() {
        try? FileManager.default.removeItem(at: url)
    }
}
