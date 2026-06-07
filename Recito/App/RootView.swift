//
//  RootView.swift
//  Recito
//
//  Top-level container. For now it hosts the Library shell; readers and sheets
//  are presented from here as the app grows.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        LibraryView()
    }
}

#Preview {
    RootView()
        .environmentObject(TalkStore.live())
        .environmentObject(DisplaySettings())
}
