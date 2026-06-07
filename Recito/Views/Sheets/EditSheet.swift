//
//  EditSheet.swift
//  Recito
//
//  Basic in-app editing of a saved talk: title, source text, and mode. Import
//  from other apps remains the main flow, but small fixes shouldn't require a
//  full re-import. Saving re-parses on next open (source text is the truth).
//

import SwiftUI

struct EditSheet: View {
    @EnvironmentObject private var store: TalkStore
    @Environment(\.dismiss) private var dismiss

    let talk: Talk

    @State private var title: String
    @State private var text: String
    @State private var mode: DocumentMode

    init(talk: Talk) {
        self.talk = talk
        _title = State(initialValue: talk.title)
        _text = State(initialValue: talk.sourceText)
        _mode = State(initialValue: talk.preferredMode)
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    titleSection
                    textSection
                    modePicker
                }
                .padding(Spacing.xl)
            }
            .background(Theme.bg)
            .navigationTitle("Edit talk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.fontWeight(.bold).disabled(!canSave)
                }
            }
        }
        .presentationDetents([.large])
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupHeaderText("Title")
            TextField("Talk title", text: $title)
                .font(.system(size: 17))
                .padding(Spacing.md)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Radius.group))
                .cardShadow()
        }
    }

    private var textSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupHeaderText("Script")
            TextEditor(text: $text)
                .scrollContentBackground(.hidden)
                .font(.system(size: 16))
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm)
                .frame(minHeight: 220)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Radius.group))
                .cardShadow()
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupHeaderText("Read as")
            Picker("Mode", selection: $mode) {
                ForEach(DocumentMode.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
        }
    }

    private func save() {
        var updated = talk
        updated.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.sourceText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        updated.preferredMode = mode
        store.update(updated)
        dismiss()
    }
}
