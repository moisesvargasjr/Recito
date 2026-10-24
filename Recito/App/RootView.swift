//
//  RootView.swift
//  Recito
//
//  Top-level container: a NavigationStack rooted at the Library, so the system
//  title, search field and toolbar (side toolbar on iPhone Duo) are available.
//  Readers and sheets are presented from the Library.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        NavigationStack {
            LibraryView()
        }
    }
}

#Preview {
    RootView()
        .environmentObject(TalkStore.live())
        .environmentObject(DisplaySettings())
}
