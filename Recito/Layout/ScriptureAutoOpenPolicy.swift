//
//  ScriptureAutoOpenPolicy.swift
//  Recito
//
//  Pure decision for the "open scripture as you approach" setting. A citation
//  is identified by where it appears (section) as well as what it cites, so a
//  verse read twice opens twice; nothing opens over a pane or sheet.
//

import Foundation

nonisolated struct ScriptureAutoOpenKey: Hashable, Sendable {
    let sectionIndex: Int
    let citationID: String
}

nonisolated enum ScriptureAutoOpenPolicy {
    /// The key to auto-open now, or nil. The caller records the key as opened
    /// only after the scripture actually opened.
    static func keyToOpen(
        enabled: Bool,
        isScriptMode: Bool,
        approaching: ScriptureAutoOpenKey?,
        scriptureBusy: Bool,
        sheetPresented: Bool,
        alreadyOpened: Set<ScriptureAutoOpenKey>
    ) -> ScriptureAutoOpenKey? {
        guard enabled, isScriptMode, !scriptureBusy, !sheetPresented,
              let approaching, !alreadyOpened.contains(approaching) else { return nil }
        return approaching
    }
}
