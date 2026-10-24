//
//  TextDisplaySheet.swift
//  Recito
//
//  Typography + appearance, the home for accessibility fonts + themes. Standard
//  SwiftUI controls bound to DisplaySettings; changes live-apply everywhere.
//

import SwiftUI

struct TextDisplaySheet: View {
    @EnvironmentObject private var settings: DisplaySettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                textSection
                appearanceSection
                voiceSection
                scriptureSection
                Section {
                    EmptyView()
                } footer: {
                    Text("These are the future home of accessibility fonts + themes — surfaced behind the Aa control on every screen.")
                }
                #if DEBUG
                developerSection
                #endif
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AXID.Text.root)
            .navigationTitle("Text & Display")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .accessibilityIdentifier(AXID.Text.done)
                }
            }
        }
        .adaptiveSheetDetents(initial: .large)
    }

    // MARK: - Sections

    private var textSection: some View {
        Section("Text") {
            Picker("Typeface", selection: $settings.typeface) {
                ForEach(Typeface.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(AXID.Text.typeface)

            sliderRow(title: "Text size", subtitle: "teleprompter text, read at a glance",
                      value: $settings.textScale, minSize: 13, maxSize: 22, identifier: AXID.Text.textSize)

            sliderRow(title: "Line spacing", subtitle: nil,
                      value: $settings.lineSpacingScale, minSize: 13, maxSize: 13,
                      identifier: AXID.Text.lineSpacing)

            Toggle(isOn: $settings.boldText) {
                labeled("Bold text", "heavier weight for low light")
            }
            .accessibilityIdentifier(AXID.Text.boldText)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            Picker("Theme", selection: $settings.theme) {
                ForEach(AppTheme.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            .accessibilityIdentifier(AXID.Text.theme)

            Toggle("Keep screen awake", isOn: $settings.keepAwake)
                .accessibilityIdentifier(AXID.Text.keepAwake)
        }
    }

    private var voiceSection: some View {
        Section {
            Picker("Recognition language", selection: $settings.recognitionLanguage) {
                ForEach(DisplaySettings.recognitionLanguages, id: \.id) { lang in
                    Text(lang.label).tag(lang.id)
                }
            }
            .accessibilityIdentifier(AXID.Text.recognitionLanguage)
        } header: {
            Text("Voice-follow")
        } footer: {
            Text("The language you'll speak in, for voice-follow. Match this to your talk, not the app's language.")
        }
    }

    private var scriptureSection: some View {
        Section {
            Toggle(isOn: $settings.autoOpenScripture) {
                labeled("Auto-open scripture", "open each linked scripture as you reach it")
            }
            .accessibilityIdentifier(AXID.Text.autoOpenScripture)

            Picker("Open scriptures in", selection: $settings.scriptureDestination) {
                ForEach(ScriptureDestination.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.menu)
            .accessibilityIdentifier(AXID.Text.scriptureDestination)
        } header: {
            Text("Scriptures")
        } footer: {
            Text("JW Library app works offline with your notes. In Recito shows the jw.org verse beside your script and needs internet.")
        }
    }

    #if DEBUG
    private var developerSection: some View {
        Section {
            Toggle(isOn: $settings.showVoiceDebug) {
                labeled("Voice debug overlay", "live recognized words, predictor lead, and pace while voice-follow runs")
            }
            .accessibilityIdentifier(AXID.Text.voiceDebug)
        } header: {
            Text("Developer")
        } footer: {
            Text("Debug builds only — not present in release.")
        }
    }
    #endif

    // MARK: - Rows

    private func sliderRow(title: String, subtitle: String?, value: Binding<Double>,
                           minSize: CGFloat, maxSize: CGFloat, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            labeled(title, subtitle)
            HStack(spacing: Spacing.md) {
                Text("A").font(.system(size: minSize)).foregroundStyle(Theme.ink2)
                    .accessibilityHidden(true)
                Slider(value: value, in: 0...1)
                    .accessibilityLabel(title)
                    .accessibilityIdentifier(identifier)
                Text("A").font(.system(size: maxSize)).foregroundStyle(Theme.ink2)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 2)
    }

    private func labeled(_ title: String, _ subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.body).foregroundStyle(Theme.ink)
            if let subtitle {
                Text(subtitle).font(.footnote).foregroundStyle(Theme.ink3)
            }
        }
    }
}

#Preview("Accessibility XXXL") {
    TextDisplaySheet()
        .environmentObject(DisplaySettings())
        .environment(\.dynamicTypeSize, .accessibility3)
}
