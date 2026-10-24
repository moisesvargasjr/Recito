//
//  ScriptureDataStore.swift
//  Recito
//
//  The verse pane's web storage. Persistent so jw.org's own cookies (notably
//  the user's privacy-consent choice) are remembered between verses, but
//  private to Recito: a dedicated store on iOS 17+, the app-local default
//  store on iOS 16. Nothing is shared with other apps, and Recito never
//  reads or scripts the stored data.
//

import WebKit

enum ScriptureDataStore {
    /// Fixed identifier of the verse pane's dedicated store (iOS 17+).
    static let identifier = UUID(uuidString: "5E1C2A7B-3D4F-4B6A-9C80-52A1F0D7E6B3")!

    static func make() -> WKWebsiteDataStore {
        if #available(iOS 17.0, *) {
            return WKWebsiteDataStore(forIdentifier: identifier)
        }
        return .default()
    }
}
