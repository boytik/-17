//
//  NestTypography.swift
//  parents
//
//  Created by Евгений on 18.02.2026.
//

import SwiftUI
import Combine

/// Typography presets for the app — readable, calm, premium feel.
enum NestTypography {

    /// Large screen title — bold and confident.
    static let cradleTitle         = Font.system(size: 28, weight: .bold, design: .rounded)

    /// Section header.
    static let guardianHeadline    = Font.system(size: 20, weight: .semibold, design: .rounded)

    /// Card title / block name.
    static let sproutLabel         = Font.system(size: 17, weight: .semibold, design: .rounded)

    /// Body text — easy on the eyes.
    static let lullabyBody         = Font.system(size: 15, weight: .regular, design: .rounded)

    /// Small detail / time / meta.
    static let whisperCaption      = Font.system(size: 13, weight: .regular, design: .rounded)

    /// Tiny badge / XP number.
    static let tinyFootprint       = Font.system(size: 11, weight: .medium, design: .rounded)

    /// Big number displays (stats, XP counters).
    static let milestoneNumber     = Font.system(size: 44, weight: .bold, design: .rounded)

    /// Tab bar labels.
    static let nestTabLabel        = Font.system(size: 10, weight: .medium, design: .rounded)
}
