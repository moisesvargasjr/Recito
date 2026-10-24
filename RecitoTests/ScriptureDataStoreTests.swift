//
//  ScriptureDataStoreTests.swift
//  RecitoTests
//
//  The verse pane remembers jw.org's consent choice, so its store persists.
//

import Testing
import WebKit
@testable import Recito

@MainActor
struct ScriptureDataStoreTests {
    @Test func storeIsPersistent() {
        #expect(ScriptureDataStore.make().isPersistent)
    }

    @Test func identifierIsStable() {
        #expect(ScriptureDataStore.identifier.uuidString == "5E1C2A7B-3D4F-4B6A-9C80-52A1F0D7E6B3")
    }
}
