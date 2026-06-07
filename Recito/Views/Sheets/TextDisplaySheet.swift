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
                Section("Text") {
                    Picker("Typeface", selection: $settings.typeface) {
                        ForEach(Typeface.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    sliderRow(
                        title: "Text size",
                        subtitle: "teleprompter text, read at a glance",
                        value: $settings.textScale,
                        minSize: 13, maxSize: 22
                    )

                    sliderRow(
                        title: "Line spacing",
                        subtitle: nil,
                        value: $settings.lineSpacingScale,
                        minSize: 13, maxSize: 13
                    )

                    Toggle(isOn: $settings.boldText) {
                        labeled("Bold text", "heavier weight for low light")
                    }
                }

                Section("Appearance") {
                    Picker("Theme", selection: $settings.theme) {
                        ForEach(AppTheme.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    Toggle("Keep screen awake", isOn: $settings.keepAwake)
                }

                Section {
                    Picker("Recognition language", selection: $settings.recognitionLanguage) {
                        ForEach(DisplaySettings.recognitionLanguages, id: \.id) { lang in
                            Text(lang.label).tag(lang.id)
                        }
                    }
                    Toggle(isOn: $settings.autoOpenScripture) {
                        labeled("Auto-open scripture", "open the reference app as you reach each linked scripture")
                    }
                } header: {
                    Text("Voice-follow")
                } footer: {
                    Text("The language you'll speak in, for voice-follow. Match this to your talk, not the app's language.")
                }

                Section {
                    EmptyView()
                } footer: {
                    Text("These are the future home of accessibility fonts + themes — surfaced behind the Aa control on every screen.")
                }
            }
            .navigationTitle("Text & Display")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.large, .medium])
    }

    private func sliderRow(title: String, subtitle: String?, value: Binding<Double>, minSize: CGFloat, maxSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            labeled(title, subtitle)
            HStack(spacing: Spacing.md) {
                Text("A").font(.system(size: minSize)).foregroundStyle(Theme.ink2)
                Slider(value: value, in: 0...1)
                Text("A").font(.system(size: maxSize)).foregroundStyle(Theme.ink2)
            }
        }
        .padding(.vertical, 2)
    }

    private func labeled(_ title: String, _ subtitle: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.system(size: 17)).foregroundStyle(Theme.ink)
            if let subtitle {
                Text(subtitle).font(.system(size: 13)).foregroundStyle(Theme.ink3)
            }
        }
    }
}
