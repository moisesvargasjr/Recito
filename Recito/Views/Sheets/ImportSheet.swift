//
//  ImportSheet.swift
//  Recito
//
//  Add a talk from pasted text, a Markdown/text file, or the Files app. Parsing
//  into the section model happens when the talk is opened.
//

import SwiftUI
import UniformTypeIdentifiers

struct ImportSheet: View {
    @EnvironmentObject private var store: TalkStore
    @EnvironmentObject private var settings: DisplaySettings
    @Environment(\.dismiss) private var dismiss
    @StateObject private var model = ImportViewModel()
    @State private var mode: DocumentMode = .script
    @State private var modePickedByUser = false

    /// Called with the newly added talk so the caller can open it if desired.
    var onAdded: ((Talk) -> Void)? = nil

    private static let importTypes: [UTType] = {
        var types: [UTType] = [.plainText, .text]
        if let md = UTType(filenameExtension: "md") { types.append(md) }
        if let markdown = UTType("net.daringfireball.markdown") { types.append(markdown) }
        return types
    }()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    pasteSection
                    importSection
                }
                .padding(Spacing.xl)
            }
            .background(Theme.bg)
            .navigationTitle("Add a talk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }
                        .fontWeight(.bold)
                        .disabled(!model.canAdd)
                }
            }
            .fileImporter(
                isPresented: $model.fileImporterPresented,
                allowedContentTypes: Self.importTypes,
                allowsMultipleSelection: false
            ) { result in
                if case .success(let urls) = result, let url = urls.first {
                    model.loadFile(at: url)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Sections

    private var pasteSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupHeaderText("Paste your script")
            ZStack(alignment: .topLeading) {
                if model.pasteText.isEmpty {
                    Text("Paste Markdown or plain text here…")
                        .foregroundStyle(Theme.ink3)
                        .padding(.horizontal, Spacing.lg)
                        .padding(.vertical, Spacing.md + 2)
                }
                TextEditor(text: $model.pasteText)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .frame(minHeight: 160)
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Radius.group))
            .cardShadow()

            Text("Headings & bullets suit outline mode; prose suits script mode — you can switch anytime.")
                .font(.system(size: 13))
                .foregroundStyle(Theme.ink2)
                .padding(.horizontal, Spacing.xs)
                .padding(.top, Spacing.md)

            modePicker
                .padding(.top, Spacing.lg)
        }
        .onChange(of: model.pasteText) { newValue in
            guard !modePickedByUser else { return }
            mode = ImportViewModel.detectMode(from: newValue)
        }
    }

    private var modePicker: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupHeaderText("Read as")
            Picker("Mode", selection: $mode) {
                ForEach(DocumentMode.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .onChange(of: mode) { _ in modePickedByUser = true }
        }
    }

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupHeaderText("Or import from")
            SheetGroup {
                SheetNavRow(title: "Markdown or text file", subtitle: ".md, .txt") {
                    model.fileImporterPresented = true
                }
                SheetNavRow(title: "Files app", showDivider: true) {
                    model.fileImporterPresented = true
                }
                SheetNavRow(
                    title: "Another app",
                    subtitle: "share sheet — e.g. a notes / Obsidian vault",
                    showDivider: true
                ) {
                    // Inbound share-sheet handling is added later; for now the
                    // file importer covers Files-based imports.
                    model.fileImporterPresented = true
                }
            }
        }
    }

    private func add() {
        guard let talk = model.makeTalk(defaultTimeLimit: settings.defaultTimeLimit, mode: mode) else { return }
        store.add(talk)
        onAdded?(talk)
        dismiss()
    }
}
