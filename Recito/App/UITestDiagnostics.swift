//
//  UITestDiagnostics.swift
//  Recito
//
//  Environment flag that tells views they are running under UI tests, so they
//  can expose extra accessibility values (positions, indices) that production
//  builds keep hidden.
//

import SwiftUI

private struct UITestDiagnosticsKey: EnvironmentKey {
    static var defaultValue: Bool { false }
}

extension EnvironmentValues {
    var uiTestDiagnostics: Bool {
        get { self[UITestDiagnosticsKey.self] }
        set { self[UITestDiagnosticsKey.self] = newValue }
    }
}
