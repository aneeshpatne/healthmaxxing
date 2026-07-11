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

    /// Sleek Accent Color — premium indigo/violet tones that feel modern and vibrant across both modes.
    static let sleekAccent = Color(uiColor: UIColor { traitCollection in
        switch traitCollection.userInterfaceStyle {
        case .dark:
            // Sleek Indigo / Violet (#9E86FF) — vibrant, premium, reads well on dark surfaces
            return UIColor(red: 0.62, green: 0.525, blue: 1.0, alpha: 1.0)
        default:
            // Deep Royal Indigo (#4338CA) — bold, sophisticated, anchors the light theme
            return UIColor(red: 0.263, green: 0.22, blue: 0.792, alpha: 1.0)
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

private struct FormaMetricCardModifier: ViewModifier {
    let horizontalPadding: CGFloat
    let padding: CGFloat
    let cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.appSecondaryBackground)
                    .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.appSeparator, lineWidth: 0.5)
            )
            .padding(.horizontal, horizontalPadding)
    }
}

extension View {
    func formaMetricCard(
        horizontalPadding: CGFloat = 16,
        padding: CGFloat = 18,
        cornerRadius: CGFloat = 20
    ) -> some View {
        modifier(
            FormaMetricCardModifier(
                horizontalPadding: horizontalPadding,
                padding: padding,
                cornerRadius: cornerRadius
            )
        )
    }
}
