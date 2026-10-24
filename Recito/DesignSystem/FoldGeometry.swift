//
//  FoldGeometry.swift
//  Recito
//
//  The only code touching GeometryProxy.reservedRegions (iOS 27.1+). Maps
//  fold (division) and camera (occlusion) regions to plain rects.
//

import SwiftUI

/// Plain-value view of the device's reserved regions, in the proxy's local space.
struct FoldSnapshot: Equatable, Sendable {
    /// All fold divisions, including inactive ones (stable layout across poses).
    var divisions: [CGRect]
    /// Camera / sensor occlusions.
    var occlusions: [CGRect]
    /// Divisions currently active (e.g. device actually folded).
    var activeDivisions: [CGRect]

    static let empty = FoldSnapshot(divisions: [], occlusions: [], activeDivisions: [])
}

@available(iOS 27.1, *)
extension GeometryProxy {
    var foldSnapshot: FoldSnapshot {
        let divisions = reservedRegions(kind: .division, options: .includeInactive)
        let occlusions = reservedRegions(kind: .occlusion)
        return FoldSnapshot(
            divisions: divisions.map(\.frame),
            occlusions: occlusions.map(\.frame),
            activeDivisions: divisions.filter(\.isActive).map(\.frame)
        )
    }
}

/// Gives content the current `FoldSnapshot` (empty before iOS 27.1).
struct FoldReader<Content: View>: View {
    private let content: (FoldSnapshot) -> Content

    init(@ViewBuilder content: @escaping (FoldSnapshot) -> Content) {
        self.content = content
    }

    var body: some View {
        GeometryReader { proxy in
            if #available(iOS 27.1, *) {
                content(proxy.foldSnapshot)
            } else {
                content(.empty)
            }
        }
    }
}
