//
//  RecitoApp.swift
//  Recito
//
//  Created by Moises Vargas Jr on 6/6/26.
//

import SwiftUI
import UIKit

@main
struct RecitoApp: App {
    @StateObject private var store: TalkStore
    @StateObject private var settings: DisplaySettings
    private let readerDependencies: ReaderDependencies
    private let config: LaunchConfiguration

    init() {
        let config = LaunchConfiguration.parse(
            arguments: ProcessInfo.processInfo.arguments,
            environment: ProcessInfo.processInfo.environment
        )
        let (store, settings, deps) = AppEnvironment.make(config)
        _store = StateObject(wrappedValue: store)
        _settings = StateObject(wrappedValue: settings)
        readerDependencies = deps
        self.config = config
        if config.disableAnimations {
            UIView.setAnimationsEnabled(false)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(settings)
                .environment(\.readerDependencies, readerDependencies)
                .environment(\.uiTestDiagnostics, config.isUITest)
                .environment(\.openTalkID, config.openTalkID)
                // The single brand accent (system blue) carries every primary
                // action, the pace marker, the cue, and the current-line rule.
                .tint(.blue)
                .preferredColorScheme(settings.theme.colorScheme)
        }
    }
}
