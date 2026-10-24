//
//  ReaderTransportPanel.swift
//  Recito
//
//  Tabletop controls on the flat half: pace bar, big timer + pace status,
//  large prev/play/next and the next-cue chip. It is content, not toolbar, so
//  it never auto-hides. While the verse pane covers the upright half it also
//  carries the pane's Done button.
//

import SwiftUI

struct ReaderTransportPanel: View {
    @ObservedObject var vm: ReaderViewModel
    let insets: EdgeInsets
    let onPrevious: () -> Void
    let onTogglePlay: () -> Void
    let onNext: () -> Void
    let onShowPacing: () -> Void
    let onOpenScripture: (ScriptureCitation) -> Void

    var body: some View {
        VStack(spacing: Spacing.lg) {
            PaceBarView(pace: vm.pace)
            timerRow
                .padding(.horizontal, Spacing.xl)
            TransportButtons(
                showsPlay: vm.mode == .script,
                isRunning: vm.isFollowRunning,
                onPrevious: onPrevious,
                onTogglePlay: onTogglePlay,
                onNext: onNext
            )
            accessoryRow
                .padding(.horizontal, Spacing.xl)
            Spacer(minLength: 0)
        }
        .padding(.leading, insets.leading)
        .padding(.trailing, insets.trailing)
        .padding(.bottom, insets.bottom)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.surface)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(AXID.Reader.transportPanel)
    }

    private var timerRow: some View {
        Button(action: onShowPacing) {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                Text(vm.elapsed.clockString)
                    .font(.largeTitle.weight(.bold).monospacedDigit())
                    .foregroundStyle(Theme.ink)
                Text("/ \(vm.timeLimit.clockString)")
                    .font(.title3.monospacedDigit())
                    .foregroundStyle(Theme.ink2)
                Spacer(minLength: Spacing.md)
                Label(vm.pace.status.label, systemImage: "circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(statusColor)
            }
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Set your pace")
        .accessibilityIdentifier(AXID.Reader.transportTimer)
    }

    @ViewBuilder
    private var accessoryRow: some View {
        HStack(spacing: Spacing.md) {
            if let citation = vm.upcomingCitation {
                CueChip(citation: citation, forceExpanded: vm.cueShouldExpand) {
                    onOpenScripture(citation)
                }
            }
            Spacer(minLength: 0)
            if vm.presentedCitation != nil {
                Button("Done") { vm.closeVerse() }
                    .font(.body.weight(.semibold))
                    .buttonStyle(.borderedProminent)
                    .frame(minHeight: Spacing.hitTarget)
                    .accessibilityLabel("Done reading verse")
                    .accessibilityIdentifier(AXID.Reader.transportPanelDone)
            } else if vm.showsResume {
                Button {
                    vm.resumeAfterVerse()
                } label: {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .frame(minHeight: Spacing.hitTarget)
                .accessibilityIdentifier(AXID.Reader.resume)
            }
        }
    }

    private var statusColor: Color {
        switch vm.pace.status {
        case .behind: return Theme.warning
        case .onPace: return Theme.good
        case .ahead: return Theme.accent
        }
    }
}
