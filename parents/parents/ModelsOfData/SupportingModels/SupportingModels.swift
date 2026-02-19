//
//  SupportingModels.swift
//  parents
//
//  Created by Евгений on 18.02.2026.
//

import SwiftUI

/// App display name — used everywhere in UI.
enum NestAppName {
    static let displayName = "Little Days: Quiet Mind"
}

enum GardenPeriod: String, CaseIterable {
    case today = "today"
    case week  = "week"

    var displayLabel: String {
        switch self {
        case .today: return "Today"
        case .week:  return "This Week"
        }
    }
}

struct DonutSlice {
    let startAngle: CGFloat
    let endAngle: CGFloat
    let color: Color
    let kind: BlockKind
}

struct ActivityLegendItem {
    let kind: BlockKind
    let color: Color
    let count: Int
}

struct InsightNestCard {
    let title: String
    let message: String
    let icon: String
    let accentColor: Color
}
