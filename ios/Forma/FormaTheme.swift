//
//  FormaTheme.swift
//  Forma
//
//  Created by Antigravity on 22/06/26.
//

import SwiftUI

extension Color {

    // MARK: - Backgrounds

    /// App background — soft warm gray in light mode, rich charcoal (not pure black) in dark mode.
    static let appBackground = Color(uiColor: UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            // Rich charcoal with a hint of blue-violet (#101014) — depth without the harshness of pure black
            return UIColor(red: 0.063, green: 0.063, blue: 0.078, alpha: 1.0)
        default:
            // Warm light gray (#F4F4F8) — softer than system gray, avoids sterile white
            return UIColor(red: 0.957, green: 0.957, blue: 0.973, alpha: 1.0)
        }
    })

    /// App secondary background — warm off-white cards in light mode, elevated charcoal in dark mode.
    static let appSecondaryBackground = Color(uiColor: UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            // Warm elevated charcoal (#1A1A20) — slightly lighter than background, subtle blue undertone
            return UIColor(red: 0.102, green: 0.102, blue: 0.125, alpha: 1.0)
        default:
            // Creamy off-white (#FAFAFE) — not sterile pure white, feels warmer
            return UIColor(red: 0.980, green: 0.980, blue: 0.996, alpha: 1.0)
        }
    })

    /// Tertiary surface — for nested elements, chart backgrounds, subtle insets.
    static let appTertiaryBackground = Color(uiColor: UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            // Slightly lifted dark (#222228)
            return UIColor(red: 0.133, green: 0.133, blue: 0.157, alpha: 1.0)
        default:
            // Very subtle cool gray (#EFEFF4)
            return UIColor(red: 0.937, green: 0.937, blue: 0.957, alpha: 1.0)
        }
    })

    // MARK: - Separators & Fills

    /// Subtle separator — barely visible line for card dividers.
    static let appSeparator = Color(uiColor: UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(white: 1.0, alpha: 0.06)
        default:
            return UIColor(white: 0.0, alpha: 0.05)
        }
    })

    /// Subtle fill — for badges, pill backgrounds, secondary containers.
    static let appSubtleFill = Color(uiColor: UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            return UIColor(white: 1.0, alpha: 0.05)
        default:
            return UIColor(white: 0.0, alpha: 0.03)
        }
    })

    // MARK: - Accent

    /// Sleek Accent Color — warm sage / champagne tones that feel premium across both modes.
    static let sleekAccent = Color(uiColor: UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            // Soft champagne-gold (#D9BF8C) — warm, premium, reads well on dark surfaces
            return UIColor(red: 0.85, green: 0.75, blue: 0.55, alpha: 1.0)
        default:
            // Deep graphite-slate (#263040) — bold, sophisticated, anchors the light theme
            return UIColor(red: 0.15, green: 0.19, blue: 0.25, alpha: 1.0)
        }
    })

    // MARK: - Card shadow

    /// Refined card shadow color — warmer and subtler than pure black shadow.
    static let cardShadow = Color(uiColor: UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            // Minimal shadow in dark mode — mostly rely on elevation difference
            return UIColor(white: 0.0, alpha: 0.25)
        default:
            // Warm shadow with a slight blue tint for depth
            return UIColor(red: 0.15, green: 0.15, blue: 0.22, alpha: 0.06)
        }
    })
}
