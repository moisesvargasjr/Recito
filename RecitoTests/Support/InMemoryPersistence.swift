//
//  InMemoryPersistence.swift
//  RecitoTests
//

import Foundation
@testable import Recito

final class InMemoryPersistence: TalkPersistence {
    private(set) var stored: [Talk]
    private(set) var saveCount = 0

    init(_ initial: [Talk] = []) { stored = initial }

    func load() -> [Talk] { stored }

    func save(_ talks: [Talk]) {
        stored = talks
        saveCount += 1
    }
}
