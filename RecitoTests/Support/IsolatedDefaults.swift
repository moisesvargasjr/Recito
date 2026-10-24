//
//  IsolatedDefaults.swift
//  RecitoTests
//
//  A throwaway UserDefaults suite so tests never touch .standard.
//

import Foundation

struct IsolatedDefaults {
    let suiteName: String
    let defaults: UserDefaults

    init() {
        suiteName = "recito.tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)!
    }

    func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
    }
}
