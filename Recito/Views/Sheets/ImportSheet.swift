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
    @FocusState private var editorFocused: Bool
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// Ask the host to present the folder picker for vault linking.
    var onLinkVault: (() -> Void)? = nil
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
                    vaultSection
                }
                .padding(Spacing.xl)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AXID.Import.root)
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.bg)
            .navigationTitle("Add a talk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier(AXID.Import.cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { add() }
                        .fontWeight(.bold)
                        .disabled(!model.canAdd)
                        .accessibilityIdentifier(AXID.Import.create)
                        .accessibilityHint("Adds the pasted script to your library")
                }
                KeyboardDoneToolbar(identifier: AXID.Import.keyboardDone) { editorFocused = false }
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
        .presentationDragIndicator(.visible)
    }

    private var editorMinHeight: CGFloat {
        LayoutMetrics.editorMinHeight(isCompactHeight: verticalSizeClass == .compact, kind: .importText)
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
                        .accessibilityHidden(true)
                }
                TextEditor(text: $model.pasteText)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .frame(minHeight: editorMinHeight)
                    .focused($editorFocused)
                    .accessibilityLabel("Script text")
                    .accessibilityIdentifier(AXID.Import.text)
            }
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Radius.group))
            .cardShadow()

            Text("Headings & bullets suit outline mode; prose suits script mode — you can switch anytime.")
                .font(.footnote)
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
            .accessibilityIdentifier(AXID.Import.mode)
            .onChange(of: mode) { _ in modePickedByUser = true }
        }
    }

    private var importSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupHeaderText("Or import from")
            SheetGroup {
                SheetNavRow(title: "Markdown or text file", subtitle: ".md, .txt",
                            identifier: AXID.Import.markdownFile) {
                    model.fileImporterPresented = true
                }
                SheetNavRow(title: "Files app", showDivider: true, identifier: AXID.Import.filesApp) {
                    model.fileImporterPresented = true
                }
            }
        }
    }

    /// Linking a folder is a different act from importing a file: the folder
    /// keeps mirroring, so edits made elsewhere show up without re-importing.
    private var vaultSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            GroupHeaderText("Or follow a folder")
            SheetGroup {
                SheetNavRow(
                    title: store.vault.isLinked ? "Change linked folder" : "Link a vault folder",
                    subtitle: store.vault.displayName.map { "Following \($0)" }
                        ?? "e.g. an Obsidian folder of talks",
                    identifier: AXID.Import.linkVault
                ) {
                    dismiss()
                    onLinkVault?()
                }
            }

            Text("Talks in a linked folder stay in sync — edit the note in Obsidian and the change is here next time you open Recito. Recito never writes into the folder.")
                .font(.footnote)
                .foregroundStyle(Theme.ink2)
                .padding(.horizontal, Spacing.xs)
                .padding(.top, Spacing.md)
        }
    }

    private func add() {
        guard let talk = model.makeTalk(defaultTimeLimit: settings.defaultTimeLimit, mode: mode) else { return }
        store.add(talk)
        onAdded?(talk)
        dismiss()
    }
}
