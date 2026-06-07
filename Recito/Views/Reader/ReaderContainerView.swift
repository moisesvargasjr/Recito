//
//  ReaderContainerView.swift
//  Recito
//
//  Owns the ReaderViewModel and swaps between the Script and Outline readers as
//  the mode changes, so switching mode preserves shared reading state.
//

import SwiftUI

struct ReaderContainerView: View {
    @EnvironmentObject private var store: TalkStore
    @StateObject var vm: ReaderViewModel

    var body: some View {
        Group {
            switch vm.mode {
            case .script:
                ScriptReaderView(vm: vm)
            case .outline:
                OutlineReaderView(vm: vm)
            }
        }
        // Persist pacing + last-used mode changes back to the library.
        .onChange(of: vm.timeLimit) { _ in persist() }
        .onChange(of: vm.mode) { _ in persist() }
    }

    private func persist() {
        var talk = vm.talk
        talk.timeLimit = vm.timeLimit
        talk.preferredMode = vm.mode
        store.update(talk)
    }
}
