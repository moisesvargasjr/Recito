//
//  ScriptReadingColumn.swift
//  Recito
//
//  The teleprompter column: every section laid out once, measured in its own
//  coordinate space (so measurements don't change while scrolling) and then
//  offset by the view position.
//

import SwiftUI

struct ScriptReadingColumn: View {
    let sections: [ScriptSection]
    let currentIndex: Int
    let font: Font
    let lineSpacing: CGFloat
    let leadingPadding: CGFloat
    let trailingPadding: CGFloat
    let verticalPadding: CGFloat
    let viewOffset: CGFloat
    let onFrames: ([Int: CGRect]) -> Void
    let onContentHeight: (CGFloat) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            ForEach(sections) { section in
                paragraph(section)
                    .background(
                        GeometryReader { proxy in
                            Color.clear.preference(
                                key: ParagraphFrameKey.self,
                                value: [section.index: proxy.frame(in: .named(ReaderSpace.name))]
                            )
                        }
                    )
            }
        }
        .padding(.leading, leadingPadding)
        .padding(.trailing, trailingPadding)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            GeometryReader { proxy in
                Color.clear.preference(key: ContentHeightKey.self, value: proxy.size.height)
            }
        )
        .coordinateSpace(name: ReaderSpace.name)
        .offset(y: -viewOffset)
        .onPreferenceChange(ParagraphFrameKey.self) { onFrames($0) }
        .onPreferenceChange(ContentHeightKey.self) { onContentHeight($0) }
    }

    @ViewBuilder
    private func paragraph(_ section: ScriptSection) -> some View {
        if section.isHeading {
            heading(section)
        } else {
            prose(section)
        }
    }

    /// A section label the speaker doesn't read — a quiet divider.
    private func heading(_ section: ScriptSection) -> some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Rectangle().fill(Theme.separator).frame(height: 1)
            Text(section.text.uppercased())
                .font(.footnote.weight(.semibold))
                .tracking(0.8)
                .foregroundStyle(Theme.ink3)
        }
        .padding(.leading, Spacing.xl)
        .padding(.top, Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }

    private func prose(_ section: ScriptSection) -> some View {
        let state = ParagraphState(index: section.index, current: currentIndex)
        return Text(section.text)
            .font(font)
            .lineSpacing(lineSpacing)
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(state.color)
            .opacity(state.opacity)
            // Constant gutter for ALL paragraphs so switching the current one
            // never changes text width/height (which would loop detection).
            .padding(.leading, Spacing.xl)
            .overlay(alignment: .leading) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Theme.accent)
                    .frame(width: 4)
                    .opacity(state == .current ? 1 : 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityAddTraits(state == .current ? .isSelected : [])
            .accessibilityIdentifier(AXID.Reader.paragraph(section.index))
    }
}

private enum ParagraphState {
    case past, current, upcoming

    init(index: Int, current: Int) {
        self = index < current ? .past : (index == current ? .current : .upcoming)
    }

    var color: Color {
        switch self {
        case .past: return Theme.ink3
        case .current: return Theme.ink
        case .upcoming: return Theme.ink2
        }
    }

    var opacity: Double { self == .upcoming ? 0.6 : 1 }
}

private enum ReaderSpace { static let name = "reader" }

private struct ParagraphFrameKey: PreferenceKey {
    static var defaultValue: [Int: CGRect] { [:] }
    static func reduce(value: inout [Int: CGRect], nextValue: () -> [Int: CGRect]) {
        value.merge(nextValue()) { _, new in new }
    }
}

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
