//
//  VoiceDebugPanel.swift
//  Recito
//
//  Voice-follow diagnostics, Debug builds only (compiled out of release):
//  the live recognition stream plus how far the predictor leads it.
//

#if DEBUG
import SwiftUI

struct VoiceDebugPanel: View {
    @ObservedObject var vm: ReaderViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(vm.voiceFollowActive ? Color.green : Color.secondary)
                    .frame(width: 7, height: 7)
                Text("VOICE DEBUG").tracking(1)
                Spacer()
                Text(String(format: "lvl %.2f", vm.audioLevel))
            }
            Text(vm.recognizedText.isEmpty ? "— no words yet —" : vm.recognizedText)
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 12) {
                Text(String(format: "lead %.1fw", vm.voiceLeadWords))
                Text(String(format: "pace %.1f w/s", vm.wordsPerSecond))
                Text(String(format: "rec %.0f", vm.voiceRecognizedIndex))
            }
            if !vm.voiceStatus.isEmpty {
                Text(vm.voiceStatus).lineLimit(1).foregroundStyle(.white.opacity(0.6))
            }
        }
        .font(.system(size: 11, weight: .semibold, design: .monospaced))
        .foregroundStyle(.white)
        .padding(10)
        .frame(maxWidth: 360, alignment: .leading)
        .background(.black.opacity(0.72), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, Spacing.md)
        .accessibilityIdentifier(AXID.Reader.voiceDebug)
    }
}
#endif
