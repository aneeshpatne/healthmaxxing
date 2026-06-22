//
//  FormaTheme.swift
//  Forma
//
//  Created by Antigravity on 22/06/26.
//

import SwiftUI

extension Color {
    /// App background — warm stone-gray in light mode, rich charcoal in dark mode.
    static let appBackground = Color(uiColor: UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            // Rich charcoal (#161619) — softer than pure black, still deep
            return UIColor(red: 0.086, green: 0.086, blue: 0.098, alpha: 1.0)
        default:
            // Warm stone-gray (#F2F1EE) — professional, avoids sterile white
            return UIColor(red: 0.949, green: 0.945, blue: 0.933, alpha: 1.0)
        }
    })

    /// App secondary background — cards, headers, grouped list containers.
    static let appSecondaryBackground = Color(uiColor: UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            // Elevated slate (#1E1E22) — subtle lift over the charcoal base
            return UIColor(red: 0.118, green: 0.118, blue: 0.133, alpha: 1.0)
        default:
            // Soft ivory (#FAFAF8) — warm but distinct from the stone-gray base
            return UIColor(red: 0.980, green: 0.980, blue: 0.973, alpha: 1.0)
        }
    })
}
