//
//  PacingSheet.swift
//  Recito
//
//  Set the talk's time limit (the pacing feature). Configurable presets +
//  custom, with a live preview of the pace bar and where you should be partway
//  through.
//

import SwiftUI

struct PacingSheet: View {
    @EnvironmentObject private var settings: DisplaySettings
    @Environment(\.dismiss) private var dismiss
    @Binding var timeLimit: TimeInterval

    @State private var showCustom = false
    @State private var customMinutes = 30

    private var selectedMinutes: Int { Int((timeLimit / 60).rounded()) }
    private var isCustom: Bool { !settings.pacingPresets.contains(selectedMinutes) }

    private static let previewFraction = 0.4

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    GroupHeaderText("Time limit")
                    presetChips
                    previewCard
                    if showCustom || isCustom { customStepper }
                    note
                }
                .padding(Spacing.xl)
            }
            .background(Theme.bg)
            .navigationTitle("Set your pace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }.fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear { customMinutes = max(1, selectedMinutes) }
    }

    private var presetChips: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(settings.pacingPresets, id: \.self) { minutes in
                chip(label: "\(minutes)", subtitle: "min",
                     selected: !isCustom && minutes == selectedMinutes) {
                    showCustom = false
                    timeLimit = TimeInterval(minutes * 60)
                }
            }
            chip(label: "Custom…", subtitle: nil, selected: isCustom) {
                showCustom = true
            }
        }
    }

    private func chip(label: String, subtitle: String?, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(label).font(.system(size: subtitle == nil ? 15 : 20, weight: subtitle == nil ? .semibold : .bold))
                if let subtitle { Text(subtitle).font(.system(size: 12)) }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .foregroundStyle(selected ? Theme.onAccent : (subtitle == nil ? Theme.ink2 : Theme.ink))
            .background(selected ? Theme.accent : Theme.surface,
                        in: RoundedRectangle(cornerRadius: 12))
            .cardShadow()
        }
        .buttonStyle(.plain)
    }

    private var previewCard: some View {
        let midTime = timeLimit * Self.previewFraction
        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Preview — pace marker at \(selectedMinutes) min")
                .font(.system(size: 15))
                .foregroundStyle(Theme.ink2)
            PaceBarView(
                pace: PaceState(youFill: Self.previewFraction, shouldBe: Self.previewFraction,
                                status: .onPace, elapsed: midTime, timeLimit: timeLimit),
                height: 10
            )
            .clipShape(Capsule())
            HStack {
                Text("0:00")
                Spacer()
                Text("~40% by \(midTime.clockString)")
                Spacer()
                Text(timeLimit.clockString)
            }
            .font(.system(size: 14, weight: .semibold).monospacedDigit())
            .foregroundStyle(Theme.ink3)
        }
        .padding(Spacing.lg)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Radius.group))
        .cardShadow()
    }

    private var customStepper: some View {
        Stepper(value: $customMinutes, in: 1...180) {
            Text("Custom: \(customMinutes) min").font(.system(size: 17))
        }
        .padding(Spacing.lg)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Radius.group))
        .cardShadow()
        .onChange(of: customMinutes) { newValue in
            timeLimit = TimeInterval(newValue * 60)
        }
    }

    private var note: some View {
        Text("Recito shows elapsed / remaining and how far through the script you should be — so you can adjust on the fly.")
            .font(.system(size: 14))
            .foregroundStyle(Theme.ink2)
            .padding(.horizontal, Spacing.xs)
    }
}
