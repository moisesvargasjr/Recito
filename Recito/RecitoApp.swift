//
//  RecitoApp.swift
//  Recito
//
//  Created by Moises Vargas Jr on 6/6/26.
//

import SwiftUI

@main
struct RecitoApp: App {
    @StateObject private var store = TalkStore.live()
    @StateObject private var settings = DisplaySettings()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(settings)
                // The single brand accent (system blue) carries every primary
                // action, the pace marker, the cue, and the current-line rule.
                .tint(.blue)
                .preferredColorScheme(settings.theme.colorScheme)
        }
    }
}
