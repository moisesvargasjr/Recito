//
//  ReaderLayoutPlanTests.swift
//  RecitoTests
//
//  Where the reader, the tabletop transport panel and the verse pane go for
//  each iPhone Duo posture and for ordinary phones.
//

import Testing
import CoreGraphics
import SwiftUI
@testable import Recito

@MainActor
struct ReaderLayoutPlanTests {
    private let cover = CGSize(width: 466, height: 678)
    private let innerLandscape = CGSize(width: 951, height: 669)
    private let innerPortrait = CGSize(width: 669, height: 951)

    private func plan(
        _ size: CGSize,
        regular: Bool = true,
        divisions: [CGRect] = [],
        active: [CGRect] = [],
        pane: Bool = false
    ) -> ReaderLayoutPlan {
        ReaderLayoutPlan.resolve(size: size, isRegularWidth: regular,
                                 divisions: divisions, activeDivisions: active,
                                 paneVisible: pane)
    }

    // MARK: Standard

    @Test func noPaneIsStandardFullScreen() {
        let p = plan(innerLandscape)
        #expect(p.kind == .standard)
        #expect(p.readerFrame == CGRect(origin: .zero, size: innerLandscape))
        #expect(p.transportFrame == nil)
        #expect(p.paneFrame == nil)
        #expect(!p.paneAsSheet)
    }

    @Test func compactWidthPresentsThePaneAsASheet() {
        let p = plan(cover, regular: false, pane: true)
        #expect(p.kind == .standard)
        #expect(p.paneAsSheet)
        #expect(p.paneFrame == nil)
        #expect(p.readerFrame == CGRect(origin: .zero, size: cover))
    }

    // MARK: Side by side

    @Test func regularLandscapeWithoutAFoldSplitsInHalf() {
        let p = plan(innerLandscape, pane: true)
        #expect(p.kind == .split)
        #expect(p.readerFrame == CGRect(x: 0, y: 0, width: 475.5, height: 669))
        #expect(p.paneFrame == CGRect(x: 475.5, y: 0, width: 475.5, height: 669))
    }

    @Test func verticalFoldSplitsAtTheFold() {
        let fold = CGRect(x: 470, y: 0, width: 12, height: 669)
        let p = plan(innerLandscape, divisions: [fold], pane: true)
        #expect(p.readerFrame == CGRect(x: 0, y: 0, width: 470, height: 669))
        #expect(p.paneFrame == CGRect(x: 482, y: 0, width: 469, height: 669))
    }

    @Test func aFoldTooCloseToTheEdgeFallsBackToHalves() {
        let fold = CGRect(x: 60, y: 0, width: 4, height: 669)
        let p = plan(innerLandscape, divisions: [fold], pane: true)
        #expect(p.readerFrame.width == 475.5)
    }

    // MARK: Stacked

    @Test func regularPortraitStacksScriptOverPane() {
        let p = plan(innerPortrait, pane: true)
        #expect(p.kind == .split)
        #expect(p.readerFrame == CGRect(x: 0, y: 0, width: 669, height: 475.5))
        #expect(p.paneFrame == CGRect(x: 0, y: 475.5, width: 669, height: 475.5))
    }

    @Test func inactiveHorizontalFoldSetsTheStackSplit() {
        let fold = CGRect(x: 0, y: 470, width: 669, height: 10)
        let p = plan(innerPortrait, divisions: [fold], pane: true)
        #expect(p.kind == .split)
        #expect(p.readerFrame.height == 470)
        #expect(p.paneFrame?.minY == 480)
    }

    // MARK: Tabletop

    @Test func activeHorizontalFoldIsTabletop() {
        let fold = CGRect(x: 0, y: 470, width: 669, height: 10)
        let p = plan(innerPortrait, divisions: [fold], active: [fold])
        #expect(p.kind == .tabletop)
        #expect(p.readerFrame == CGRect(x: 0, y: 0, width: 669, height: 470))
        #expect(p.transportFrame == CGRect(x: 0, y: 480, width: 669, height: 471))
        #expect(p.paneFrame == nil)
    }

    @Test func tabletopPaneReplacesTheUprightHalf() {
        let fold = CGRect(x: 0, y: 470, width: 669, height: 10)
        let p = plan(innerPortrait, divisions: [fold], active: [fold], pane: true)
        #expect(p.kind == .tabletop)
        #expect(p.paneFrame == p.readerFrame)
        #expect(p.transportFrame != nil)
        #expect(!p.paneAsSheet)
    }

    @Test func tabletopOnACompactDisplayStillUsesThePanel() {
        let fold = CGRect(x: 0, y: 330, width: 466, height: 8)
        let p = plan(cover, regular: false, divisions: [fold], active: [fold], pane: true)
        #expect(p.kind == .tabletop)
        #expect(!p.paneAsSheet)
    }

    // MARK: Region insets

    @Test func regionInsetsOnlyKeepEdgesTouchingTheWindow() {
        let safe = EdgeInsets(top: 50, leading: 0, bottom: 30, trailing: 70)
        let size = CGSize(width: 951, height: 669)
        let left = CGRect(x: 0, y: 0, width: 470, height: 669)
        let right = CGRect(x: 482, y: 0, width: 469, height: 669)
        let l = ReaderLayoutPlan.insets(of: left, in: size, safe: safe)
        let r = ReaderLayoutPlan.insets(of: right, in: size, safe: safe)
        #expect(l == EdgeInsets(top: 50, leading: 0, bottom: 30, trailing: 0))
        #expect(r == EdgeInsets(top: 50, leading: 0, bottom: 30, trailing: 70))
    }

    @Test func regionInsetsForTabletopHalves() {
        let safe = EdgeInsets(top: 50, leading: 0, bottom: 30, trailing: 0)
        let size = CGSize(width: 669, height: 951)
        let top = CGRect(x: 0, y: 0, width: 669, height: 470)
        let bottom = CGRect(x: 0, y: 480, width: 669, height: 471)
        #expect(ReaderLayoutPlan.insets(of: top, in: size, safe: safe).bottom == 0)
        #expect(ReaderLayoutPlan.insets(of: bottom, in: size, safe: safe).top == 0)
        #expect(ReaderLayoutPlan.insets(of: bottom, in: size, safe: safe).bottom == 30)
    }

    @Test func diagnosticsLabelsMatchTheUITestContract() {
        #expect(ReaderLayoutPlan.Kind.standard.rawValue == "standard")
        #expect(ReaderLayoutPlan.Kind.tabletop.rawValue == "tabletop")
        #expect(ReaderLayoutPlan.Kind.split.rawValue == "split")
    }
}
