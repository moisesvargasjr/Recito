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
    /// Narrowest chip before the row wraps; grows with Dynamic Type.
    @ScaledMetric(relativeTo: .title3) private var chipMinWidth: CGFloat = 76

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
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier(AXID.Pacing.root)
            .background(Theme.bg)
            .navigationTitle("Set your pace")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier(AXID.Pacing.cancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .accessibilityIdentifier(AXID.Pacing.done)
                }
            }
        }
        .adaptiveSheetDetents(initial: .medium)
        .onAppear { customMinutes = max(1, selectedMinutes) }
    }

    private var presetChips: some View {
        BalancedChipGrid(minItemWidth: chipMinWidth, spacing: Spacing.sm) {
            ForEach(settings.pacingPresets, id: \.self) { minutes in
                chip(label: "\(minutes)", subtitle: "min",
                     selected: !isCustom && minutes == selectedMinutes,
                     accessibilityLabel: "\(minutes) minutes",
                     identifier: AXID.Pacing.preset(minutes)) {
                    showCustom = false
                    timeLimit = TimeInterval(minutes * 60)
                }
            }
            chip(label: "Custom…", subtitle: nil, selected: isCustom,
                 accessibilityLabel: "Custom time", identifier: AXID.Pacing.custom) {
                showCustom = true
            }
        }
    }

    private func chip(label: String, subtitle: String?, selected: Bool, accessibilityLabel: String,
                      identifier: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Text(label).font(subtitle == nil ? .subheadline.weight(.semibold) : .title3.bold())
                if let subtitle { Text(subtitle).font(.caption) }
            }
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: Spacing.hitTarget, maxHeight: .infinity)
            .padding(.vertical, Spacing.md)
            .foregroundStyle(selected ? Theme.onAccent : (subtitle == nil ? Theme.ink2 : Theme.ink))
            .background(selected ? Theme.accent : Theme.surface,
                        in: RoundedRectangle(cornerRadius: 12))
            .cardShadow()
            .contentShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    private var previewCard: some View {
        let midTime = timeLimit * Self.previewFraction
        return VStack(alignment: .leading, spacing: Spacing.md) {
            Text("Preview — pace marker at \(selectedMinutes) min")
                .font(.subheadline)
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
            .font(.footnote.weight(.semibold).monospacedDigit())
            .foregroundStyle(Theme.ink3)
        }
        .padding(Spacing.lg)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Radius.group))
        .cardShadow()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(AXID.Pacing.preview)
    }

    private var customStepper: some View {
        Stepper(value: $customMinutes, in: 1...180) {
            Text("Custom: \(customMinutes) min").font(.body)
        }
        .accessibilityIdentifier(AXID.Pacing.stepper)
        .padding(Spacing.lg)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Radius.group))
        .cardShadow()
        .onChange(of: customMinutes) { newValue in
            timeLimit = TimeInterval(newValue * 60)
        }
    }

    private var note: some View {
        Text("Recito shows elapsed / remaining and how far through the script you should be — so you can adjust on the fly.")
            .font(.footnote)
            .foregroundStyle(Theme.ink2)
            .padding(.horizontal, Spacing.xs)
    }
}

#Preview("Accessibility XXXL") {
    PacingSheet(timeLimit: .constant(15 * 60))
        .environmentObject(DisplaySettings())
        .environment(\.dynamicTypeSize, .accessibility3)
}
