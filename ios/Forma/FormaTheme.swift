import SwiftUI
import Charts

// MARK: - Foundations

enum FormaSpacing {
    /// 4px base grid.
    static let xxs: CGFloat = 4   // space-1
    static let xs: CGFloat = 8    // space-2
    static let sm: CGFloat = 12   // space-3
    static let md: CGFloat = 16   // space-4
    static let lg: CGFloat = 20   // space-5
    static let xl: CGFloat = 24   // space-6
    static let xxl: CGFloat = 32  // space-8
    static let xxxl: CGFloat = 40 // space-10

    static let screenGutter = lg
    static let cardGap = lg
    static let sectionGap = xl
    static let cardInset = xl

    /// Unified vertical rhythm inside cards (header → content → divider → callout).
    static let cardContent = lg
}

enum FormaSemicircularGaugeLayout {
    static let aspectRatio: CGFloat = 2
    static let strokeWidth: CGFloat = 16
    static let labelInset: CGFloat = 30
    static let markerDiameter: CGFloat = 16
    static let markerStrokeWidth: CGFloat = 3
    static let scoreOffset: CGFloat = 20
}

enum FormaRadius {
    /// Soft, confident geometry — not inflated.
    static let badge: CGFloat = 12      // radius-sm
    static let inset: CGFloat = 18      // radius-md
    static let card: CGFloat = 24       // radius-lg
    static let hero: CGFloat = 32       // radius-xl
    /// Fully rounded CTAs and segmented controls.
    static let action: CGFloat = 999    // radius-pill
    static let pill: CGFloat = 999
}

enum FormaTypography {
    /// App-wide UI face — native SF Pro for clarity and Dynamic Type support.
    static let design: Font.Design = .default

    static func wordmark(size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: design)
    }

    /// Prefer this for any ad-hoc size so the face stays consistent.
    static func system(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: design)
    }

    /// Dynamic Type text styles with the app face (use instead of `.font(FormaTypography.textStyle(.body))` etc.).
    static func textStyle(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: design, weight: weight)
    }

    /// Quiet metadata / chip labels (sentence case; avoid all-caps except short tags).
    static let eyebrow = system(size: 12, weight: .semibold)
    /// Value bean / pill numbers (FormaValueBadge).
    static let valueBadge = system(size: 16, weight: .bold)
    /// Card titles — Heading 3 energy.
    static let cardTitle = system(size: 20, weight: .semibold)
    /// Screen / section titles — Heading 2.
    static let sectionTitle = system(size: 26, weight: .bold)
    static let action = system(size: 16, weight: .semibold)
    static let body = system(size: 16, weight: .regular)
    static let supporting = system(size: 14, weight: .medium)
    static let metricSmall = system(size: 28, weight: .bold)
    /// Display L — primary numeric readouts.
    static let metric = system(size: 52, weight: .bold)
    /// Units stay 35–50% of the metric.
    static let unit = system(size: 16, weight: .semibold)
    static let chartLabel = system(size: 11, weight: .medium)

    /// Gauge center readout.
    static let gaugeValue = system(size: 48, weight: .bold)
    static let micro = system(size: 11, weight: .semibold)
    static let sectionHeadline = system(size: 17, weight: .semibold)
}

// MARK: - Motion

/// Short feedback for direct interactions. Navigation remains system-owned.
enum FormaMotion {
    static let tap = Animation.easeOut(duration: 0.10)
    static let fast = Animation.easeOut(duration: 0.12)
    static let standard = Animation.easeOut(duration: 0.15)
    static let selection = fast
    static let interactive = fast
    static let insertion = fast
    static let removal = fast
    static let dismissal = fast
    static let success = fast
    static let successSoft = fast
    static let successBurst = fast
    static let dataReveal = Animation.linear(duration: 0)
    static let navigation: Animation? = nil
    static let presentation: Animation? = nil
    static let press = tap
    static let move = fast

    static func preferred(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}

enum FormaPressDepth {
    case subtle
    case standard
    case prominent

    fileprivate var scale: CGFloat {
        switch self {
        case .subtle: 0.985
        case .standard: 0.97
        case .prominent: 0.96
        }
    }

    fileprivate var pressedOpacity: Double {
        switch self {
        case .subtle: 0.94
        case .standard: 0.90
        case .prominent: 0.92
        }
    }
}

struct FormaPressableButtonStyle: ButtonStyle {
    var depth: FormaPressDepth = .standard

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isEnabled ? (configuration.isPressed ? depth.pressedOpacity : 1) : 0.48)
            .animation(FormaMotion.preferred(FormaMotion.tap, reduceMotion: reduceMotion), value: configuration.isPressed)
            .formaHoverEffect()
    }
}

/// Saturated primary actions stay legible over every surface.
struct FormaPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(FormaTypography.action)
            .padding(.horizontal, FormaSpacing.lg)
            .padding(.vertical, FormaSpacing.sm)
            .foregroundStyle(Color.actionForeground)
            .background(Color.actionInk, in: Capsule())
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.48)
    }
}

struct FormaIconButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Color.sleekAccent)
            .background(Color.appSecondaryBackground, in: Circle())
            .overlay(Circle().strokeBorder(Color.appBorder, lineWidth: 1))
            .opacity(isEnabled ? (configuration.isPressed ? 0.8 : 1) : 0.48)
    }
}

extension View {
    @ViewBuilder
    func formaHoverEffect() -> some View {
        #if os(iOS)
        hoverEffect(.highlight)
        #else
        self
        #endif
    }
}

extension View {
    /// Kept as a compatibility hook. Screen content appears immediately; system
    /// navigation and meaningful data feedback own the remaining motion.
    func formaEntrance(order: Int = 0) -> some View {
        self
    }
}

// MARK: - Palette

// Crisp neutral surfaces with a black/white primary accent. Color is reserved
// for data and status, with softly tinted cards keeping the UI composed.
extension Color {
    private static func adaptive(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 255) / 255,
                           green: CGFloat((hex >> 8) & 255) / 255,
                           blue: CGFloat(hex & 255) / 255, alpha: 1)
        })
    }
    static let appBackground = adaptive(light: 0xF5F5F3, dark: 0x090909)
    static let appSecondaryBackground = adaptive(light: 0xFFFFFF, dark: 0x161616)
    static let appTertiaryBackground = adaptive(light: 0xECECEA, dark: 0x242424)
    static let appChartBackground = adaptive(light: 0xF0F0EE, dark: 0x111111)
    static let appElevatedBackground = adaptive(light: 0xFFFFFF, dark: 0x292929)
    static let appInverseSurface = adaptive(light: 0x121212, dark: 0xFFFFFF)
    static let appSeparator = adaptive(light: 0xD9D9D5, dark: 0x393939)
    static let appBorder = adaptive(light: 0xCECECA, dark: 0x454545)
    static let appBorderStrong = adaptive(light: 0x70706C, dark: 0xA8A8A3)
    static let appSubtleFill = adaptive(light: 0xE8E8E5, dark: 0x272727)
    static let formaTextPrimary = adaptive(light: 0x121212, dark: 0xFFFFFF)
    static let formaTextSecondary = adaptive(light: 0x52524E, dark: 0xC7C7C2)
    static let sleekAccent = adaptive(light: 0x171717, dark: 0xFFFFFF)
    static let formaAccentSecondary = adaptive(light: 0x007B83, dark: 0x42D7DF)
    static let actionInk = adaptive(light: 0x171717, dark: 0xFFFFFF)
    static let actionForeground = adaptive(light: 0xFFFFFF, dark: 0x111111)
    static let formaFocusRing = adaptive(light: 0x171717, dark: 0xFFFFFF)
    static let formaPositive = adaptive(light: 0x087A48, dark: 0x43D68B)
    static let formaCaution = adaptive(light: 0x965600, dark: 0xFFB84D)
    static let formaNegative = adaptive(light: 0xC32645, dark: 0xFF6F8B)
    static let formaChartBone = adaptive(light: 0xA45E00, dark: 0xFFC35C)

    // A single harmonious progression shared by every segmented gauge.
    static let formaGaugeLow = adaptive(light: 0xD2385B, dark: 0xFF7089)
    static let formaGaugeCaution = adaptive(light: 0xA85E00, dark: 0xFFB545)
    static let formaGaugeTarget = adaptive(light: 0x07824D, dark: 0x3DDC8A)
    static let formaGaugeStrong = adaptive(light: 0x007F83, dark: 0x35D1D2)
    static let formaGaugePeak = adaptive(light: 0x2169C9, dark: 0x69A7FF)

    static let formaNegativeFill = adaptive(light: 0xD93655, dark: 0xFF6F8B)

    static let formaInfo = Color.formaAccentSecondary
    static let formaChartPrimary = Color.sleekAccent
    static let formaChartMuscle = adaptive(light: 0x146BD1, dark: 0x62A9FF)
    static let formaChartFat = Color.formaAccentSecondary
    static let formaChartVisceral = Color.formaCaution
    static let formaChartSubcutaneous = Color.formaNegative
    static let cardShadow = Color.black.opacity(0.09)
}

// MARK: - Background and surfaces

struct FormaBackground: View {
    var accent: Color? = nil
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.appBackground
            if let accent {
                RadialGradient(
                    colors: [accent.opacity(0.14), accent.opacity(0)],
                    center: .topTrailing,
                    startRadius: 0,
                    endRadius: 330
                )
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// A restrained accent wash for the top of detail screens.
struct FormaAccentWash: View {
    let accent: Color
    var topExtension: CGFloat = 0
    var body: some View {
        LinearGradient(
            colors: [accent.opacity(0.16), accent.opacity(0.045), .clear],
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .frame(height: 280 + topExtension)
        .accessibilityHidden(true)
    }
}

enum FormaSurfaceStyle: Equatable {
    case inset
    case chart
    case card
    case hero
    case floating

    var radius: CGFloat {
        switch self {
        case .inset: FormaRadius.inset
        case .chart: FormaRadius.inset
        case .card: FormaRadius.card
        case .hero: FormaRadius.hero
        case .floating: FormaRadius.hero
        }
    }

    var fill: Color {
        switch self {
        case .inset: .appTertiaryBackground
        case .chart: .appChartBackground
        case .card, .hero, .floating: .appSecondaryBackground
        }
    }
}

private struct FormaSurfaceModifier: ViewModifier {
    let style: FormaSurfaceStyle
    let padding: CGFloat?
    let tint: Color?

    @Environment(\.colorSchemeContrast) private var colorSchemeContrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: style.radius, style: .continuous)
        let resolvedTint = tint ?? .appBorder

        Group {
            if let padding {
                content.padding(padding)
            } else {
                content
            }
        }
        .background {
            if style == .inset || style == .chart {
                shape
                    .fill(style.fill)
                    .overlay {
                        if tint != nil {
                            shape.fill(resolvedTint.opacity(0.065))
                        }
                    }
            } else {
                let base = shape
                    .fill(style.fill)
                    .overlay {
                        if let tint {
                            shape.fill(tint.opacity(0.055))
                        }
                    }

                base.shadow(
                    color: Color.cardShadow,
                    radius: style == .floating || style == .hero ? 12 : 8,
                    x: 0,
                    y: style == .floating || style == .hero ? 8 : 4
                )
            }
        }
        .overlay {
            if colorSchemeContrast == .increased || tint != nil {
                shape.strokeBorder(
                    colorSchemeContrast == .increased
                        ? Color.appBorderStrong.opacity(0.55)
                        : resolvedTint.opacity(0.20),
                    lineWidth: colorSchemeContrast == .increased ? 1 : 0.75
                )
            }
        }
    }
}

extension View {
    func formaSurface(
        _ style: FormaSurfaceStyle = .card,
        padding: CGFloat? = FormaSpacing.cardInset,
        tint: Color? = nil
    ) -> some View {
        modifier(FormaSurfaceModifier(style: style, padding: padding, tint: tint))
    }

    func formaMetricCard(padding: CGFloat = FormaSpacing.cardInset, tint: Color? = nil) -> some View {
        formaSurface(.card, padding: padding, tint: tint)
    }
}

// MARK: - Shared building blocks

struct FormaCardHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    let trailing: Trailing
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        _ title: String,
        subtitle: String? = nil,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing()
    }

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: FormaSpacing.sm) {
                    titleContent
                    trailing
                }
            } else {
                HStack(alignment: subtitle == nil ? .center : .top, spacing: FormaSpacing.sm) {
                    titleContent
                    Spacer(minLength: FormaSpacing.xs)
                    trailing
                }
            }
        }
    }

    private var titleContent: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(FormaTypography.cardTitle)
                .tracking(-0.4)
                .foregroundStyle(.primary)

            if let subtitle, !subtitle.isEmpty, subtitle != title {
                Text(subtitle)
                    .font(FormaTypography.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

extension FormaCardHeader where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil) {
        self.init(title, subtitle: subtitle) { EmptyView() }
    }
}

/// Consistent hairline separator used between card content and insights.
struct FormaDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.appSeparator)
            .frame(height: 0.5)
    }
}

/// Soft tinted capsule used for headline values and statuses.
/// Default tint is neutral secondary — pass brand/status only when meaning requires it.
/// Sentence case; short metadata only.
struct FormaValueBadge: View {
    let text: String
    var tint: Color = .secondary

    var body: some View {
        Text(text)
            .font(FormaTypography.valueBadge)
            .monospacedDigit()
            .lineLimit(2)
            .minimumScaleFactor(0.75)
            .foregroundStyle(tint)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(tint.opacity(0.12), in: Capsule())
    }
}

/// Small tinted tile for the original Forma vector icons.
/// Minimal iconography — quiet fill, no decorative stroke.
struct FormaIconTile: View {
    let systemImage: String
    var tint: Color = .secondary
    var size: CGFloat = 32
    var radius: CGFloat = FormaRadius.badge
    var symbolFont: Font = FormaTypography.system(size: 14, weight: .semibold)

    var body: some View {
        Image(forma: systemImage)
            .resizable().scaledToFit()
            .frame(width: size * 0.56, height: size * 0.56)
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(tint.opacity(0.12))
            }
    }
}

struct FormaCallout: View {
    let text: String
    var systemImage = "sparkles"
    var tint: Color = .secondary

    var body: some View {
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack(alignment: .top, spacing: FormaSpacing.sm) {
                FormaIconTile(systemImage: systemImage, tint: tint)

                Text(text)
                    .font(FormaTypography.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)
            }
        }
    }
}

/// Visible focus ring for custom controls (WCAG 2.2 focus appearance).
struct FormaFocusRingModifier: ViewModifier {
    var isFocused: Bool
    var cornerRadius: CGFloat = FormaRadius.inset

    func body(content: Content) -> some View {
        content
            .overlay {
                if isFocused {
                    RoundedRectangle(cornerRadius: cornerRadius + 2, style: .continuous)
                        .strokeBorder(Color.formaFocusRing, lineWidth: 2)
                        .padding(-3)
                        .allowsHitTesting(false)
                }
            }
    }
}

extension View {
    func formaFocusRing(isFocused: Bool, cornerRadius: CGFloat = FormaRadius.inset) -> some View {
        modifier(FormaFocusRingModifier(isFocused: isFocused, cornerRadius: cornerRadius))
    }
}

// MARK: - Status screens

/// Consistent full-width status presentation for empty, error, and placeholder
/// states: tinted icon disc, title, message, and an optional glass action.
struct FormaStatusView: View {
    let title: String
    let message: String
    var systemImage = "doc.text.magnifyingglass"
    var tint: Color = .secondary
    var actionTitle: String? = nil
    var actionTint: Color? = nil
    var action: (() -> Void)? = nil

    @State private var actionFeedbackNonce = 0

    var body: some View {
        VStack(spacing: FormaSpacing.xl) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 72, height: 72)

                Image(forma: systemImage)
                    .resizable().scaledToFit().frame(width: 26, height: 26)
                    .foregroundStyle(tint)
            }

            VStack(spacing: FormaSpacing.sm) {
                Text(title)
                    .font(FormaTypography.sectionTitle)
                    .foregroundStyle(.primary)

                Text(message)
                    .font(FormaTypography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button {
                    actionFeedbackNonce += 1
                    action()
                } label: {
                    Text(actionTitle)
                        .font(FormaTypography.action)
                        .frame(minHeight: 52)
                        .padding(.horizontal, FormaSpacing.xl)
                }
                .buttonStyle(FormaPrimaryButtonStyle())
                .buttonBorderShape(.capsule)
                .tint(actionTint ?? tint)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, FormaSpacing.xl)
        .padding(.vertical, 88)
        .accessibilityElement(children: .contain)
        .formaFeedback(.softImpact, trigger: actionFeedbackNonce)
    }
}

enum FormaLoadingIndicatorSize: Equatable {
    case compact
    case medium
}

/// System spinner used for everyday indeterminate loading.
/// Loading copy belongs to the parent so VoiceOver hears one useful status.
struct FormaLoadingIndicator: View {
    var size: FormaLoadingIndicatorSize = .compact
    var tint: Color = .sleekAccent

    var body: some View {
        ProgressView()
            .progressViewStyle(.circular)
            .controlSize(size == .medium ? .regular : .small)
            .tint(tint)
            .accessibilityHidden(true)
    }
}

/// Lightweight status shown above cached report content while a newer report is
/// loading. Existing content remains readable and interactive.
struct FormaRefreshStatus: View {
    let message: String

    var body: some View {
        HStack(spacing: FormaSpacing.sm) {
            FormaLoadingIndicator()

            Text(message)
                .font(FormaTypography.supporting.weight(.medium))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, FormaSpacing.md)
        .padding(.vertical, FormaSpacing.sm)
        .background(Color.appTertiaryBackground, in: Capsule())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Transitions

enum FormaTransition {
    /// Content swap without implying vertical hierarchy.
    static let fade: AnyTransition = .identity

    /// Child material appearing near a parent (footer under record circle).
    static let rise: AnyTransition = .identity

    /// Gentle rise-and-fade used when cards and screens swap content.
    static let card: AnyTransition = rise

    /// Prefer fade under Reduce Motion.
    static func content(reduceMotion: Bool) -> AnyTransition {
        reduceMotion ? fade : rise
    }
}

/// Compatibility modifier: launch content is immediately available.
struct FormaLaunchReveal: ViewModifier {
    func body(content: Content) -> some View { content }
}

extension View {
    func formaLaunchReveal() -> some View {
        modifier(FormaLaunchReveal())
    }
}

// MARK: - Semicircular gauge

/// One colored zone of a semicircular gauge.
struct FormaGaugeSegment {
    let color: Color
    let min: Double
    let max: Double
}

/// Shared semicircular gauge: colored zones, tick labels, a value marker that
/// sweeps in on appear, and a large center readout with a tracked caption.
struct FormaSemicircularGauge: View {
    let value: Double
    var accent: Color
    let segments: [FormaGaugeSegment]
    let range: ClosedRange<Double>
    var tickLabels: [Double] = []
    var labelSuffix = ""
    var valueText: String
    var caption: String
    var captionColor: Color = .secondary

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var animatedValue: Double?

    private var span: Double { range.upperBound - range.lowerBound }

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let radius = width / 2
            let strokeWidth = FormaSemicircularGaugeLayout.strokeWidth
            let presentedValue = animatedValue ?? range.lowerBound

            ZStack {
                // Colored zones
                ZStack {
                    ForEach(0..<segments.count, id: \.self) { index in
                        let segment = segments[index]
                        let startTrim = CGFloat((segment.min - range.lowerBound) / span) * 0.5
                        let endTrim = CGFloat((segment.max - range.lowerBound) / span) * 0.5

                        Circle()
                            .trim(from: startTrim, to: endTrim)
                            .stroke(segment.color.gradient, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                            .rotationEffect(.degrees(180))
                    }
                }
                .frame(width: width, height: width)
                .position(x: width / 2, y: height)

                // Tick labels
                ForEach(tickLabels, id: \.self) { labelValue in
                    let t = (labelValue - range.lowerBound) / span
                    let angle = Angle(degrees: 180 - t * 180)
                    let labelRadius = radius - FormaSemicircularGaugeLayout.labelInset

                    Text("\(String(format: "%.0f", labelValue))\(labelSuffix)")
                        .font(FormaTypography.textStyle(.caption2, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .position(
                            x: width / 2 + labelRadius * CGFloat(cos(angle.radians)),
                            y: height - labelRadius * CGFloat(sin(angle.radians))
                        )
                }

                FormaGaugeMarker(
                    value: presentedValue,
                    range: range,
                    center: CGPoint(x: width / 2, y: height),
                    radius: radius,
                    accent: accent
                )

                // Center readout
                VStack(spacing: 2) {
                    Text(valueText)
                        .font(FormaTypography.gaugeValue)
                        .foregroundStyle(.primary)

                    Text(caption)
                        .font(FormaTypography.textStyle(.caption, weight: .bold))
                        .foregroundStyle(captionColor)
                        .tracking(0.6)
                }
                .position(x: width / 2, y: height - FormaSemicircularGaugeLayout.scoreOffset)
            }
        }
        .aspectRatio(FormaSemicircularGaugeLayout.aspectRatio, contentMode: .fit)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(caption)
        .accessibilityValue("\(valueText), range \(formatted(range.lowerBound)) to \(formatted(range.upperBound))\(labelSuffix)")
        .onAppear { animateToValue() }
        .onChange(of: value) { _, _ in animateToValue() }
    }

    private func formatted(_ value: Double) -> String {
        value.rounded() == value ? String(format: "%.0f", value) : String(format: "%.1f", value)
    }

    private func animateToValue() {
        let clamped = min(range.upperBound, max(range.lowerBound, value))
        // Skip re-sweeps when the value did not change (tab revisits, layout).
        if let animatedValue, abs(animatedValue - clamped) < 0.000_1 {
            return
        }

        animatedValue = clamped
    }
}

/// Animates the scalar gauge value instead of its final x/y position. This
/// recalculates the angle on every frame, keeping the marker on the arc.
private struct FormaGaugeMarker: View, Animatable {
    var value: Double
    let range: ClosedRange<Double>
    let center: CGPoint
    let radius: CGFloat
    let accent: Color

    var animatableData: Double {
        get { value }
        set { value = newValue }
    }

    var body: some View {
        let span = range.upperBound - range.lowerBound
        let progress = max(0, min(1, (value - range.lowerBound) / span))
        let angle = Angle(degrees: 180 - progress * 180)

        Circle()
            .fill(Color.appSecondaryBackground)
            .frame(
                width: FormaSemicircularGaugeLayout.markerDiameter,
                height: FormaSemicircularGaugeLayout.markerDiameter
            )
            .overlay(
                Circle().stroke(accent, lineWidth: FormaSemicircularGaugeLayout.markerStrokeWidth)
            )
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
            .position(
                x: center.x + radius * CGFloat(cos(angle.radians)),
                y: center.y - radius * CGFloat(sin(angle.radians))
            )
    }
}

/// One category in a ``FormaCategoryLegend``.
struct FormaLegendCategory {
    let name: String
    let range: String
    let color: Color
    let min: Double
    let max: Double
}

/// Segmented-bar legend that highlights the category the selected value falls into.
struct FormaCategoryLegend: View {
    let categories: [FormaLegendCategory]
    let selectedValue: Double
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize, let selectedCategory {
                HStack(alignment: .top, spacing: FormaSpacing.sm) {
                    Image(forma: "checkmark.circle.fill")
                        .foregroundStyle(selectedCategory.color)

                    VStack(alignment: .leading, spacing: FormaSpacing.xxs) {
                        Text(selectedCategory.name)
                            .font(FormaTypography.textStyle(.body, weight: .semibold))
                        Text("Selected range \(selectedCategory.range)")
                            .font(FormaTypography.textStyle(.caption))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(spacing: 6) {
                    ForEach(0..<categories.count, id: \.self) { index in
                        category(categories[index], isSelected: isSelected(index))
                    }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Category")
        .accessibilityValue(selectedCategory.map { "\($0.name), \($0.range)" } ?? "Not available")
    }

    private var selectedCategory: FormaLegendCategory? {
        categories.first {
            selectedValue >= $0.min
                && (selectedValue < $0.max || ($0.max == categories.last?.max && selectedValue == $0.max))
        }
    }

    private func isSelected(_ index: Int) -> Bool {
        let category = categories[index]
        return selectedValue >= category.min
            && (selectedValue < category.max || (index == categories.indices.last && selectedValue == category.max))
    }

    private func category(_ category: FormaLegendCategory, isSelected: Bool) -> some View {
        VStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(
                    isSelected
                        ? AnyShapeStyle(category.color.gradient)
                        : AnyShapeStyle(category.color.opacity(0.55))
                )
                .frame(height: 4)

            Text(category.name)
                .font(FormaTypography.textStyle(.caption2, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .primary : .secondary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            Text(category.range)
                .font(FormaTypography.micro)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Skeleton loading

/// Static skeletons avoid repeated compositing while data is loading.
struct ShimmerModifier: ViewModifier {
    func body(content: Content) -> some View { content }
}

extension View {
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
}

/// Placeholder block used to compose skeleton layouts.
struct FormaSkeletonBlock: View {
    var width: CGFloat? = nil
    var height: CGFloat = 14
    var radius: CGFloat = 6
    var opacity: Double = 0.10

    var body: some View {
        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(Color.secondary.opacity(opacity))
            .frame(width: width, height: height)
    }
}

enum FormaSkeletonCardKind {
    case gauge
    case narrative
    case chart
}

struct FormaSkeletonCard: View {
    var kind: FormaSkeletonCardKind = .chart

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.lg) {
            VStack(alignment: .leading, spacing: FormaSpacing.xs) {
                FormaSkeletonBlock(width: 150, height: 18, opacity: 0.14)
                FormaSkeletonBlock(width: 230, height: 13, opacity: 0.08)
            }

            skeletonContent

            FormaDivider()

            HStack(spacing: FormaSpacing.sm) {
                FormaSkeletonBlock(width: 32, height: 32, radius: 9, opacity: 0.10)

                VStack(alignment: .leading, spacing: 6) {
                    FormaSkeletonBlock(width: 130, height: 13, opacity: 0.10)
                    FormaSkeletonBlock(width: 200, height: 11, opacity: 0.07)
                }

                Spacer()
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
        .shimmering()
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var skeletonContent: some View {
        switch kind {
        case .gauge:
            ZStack(alignment: .bottom) {
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(
                        Color.secondary.opacity(0.08),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(180))
                    .frame(maxWidth: 260)
                    .aspectRatio(1, contentMode: .fit)

                VStack(spacing: FormaSpacing.xs) {
                    FormaSkeletonBlock(width: 88, height: 34, radius: 10, opacity: 0.14)
                    FormaSkeletonBlock(width: 64, height: 11, opacity: 0.08)
                }
                .padding(.bottom, FormaSpacing.sm)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 145)
            .clipped()

        case .narrative:
            VStack(alignment: .leading, spacing: FormaSpacing.sm) {
                FormaSkeletonBlock(width: 210, height: 18, opacity: 0.12)
                FormaSkeletonBlock(height: 13, opacity: 0.08)
                FormaSkeletonBlock(height: 13, opacity: 0.08)
                FormaSkeletonBlock(width: 180, height: 13, opacity: 0.08)
            }
            .frame(maxWidth: .infinity, minHeight: 120, alignment: .topLeading)
            .padding(FormaSpacing.md)
            .background(Color.appSubtleFill, in: RoundedRectangle(cornerRadius: FormaRadius.inset))

        case .chart:
            VStack(alignment: .leading, spacing: FormaSpacing.xs) {
                Spacer()
                HStack(alignment: .bottom, spacing: FormaSpacing.xs) {
                    ForEach([0.34, 0.56, 0.44, 0.76, 0.64, 0.88], id: \.self) { height in
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))
                            .frame(maxWidth: .infinity)
                            .frame(height: 110 * height)
                    }
                }
            }
            .frame(height: 150)
            .padding(.horizontal, FormaSpacing.sm)
            .background(Color.appSubtleFill, in: RoundedRectangle(cornerRadius: FormaRadius.inset))
        }
    }
}

// MARK: - Charts

enum FormaChartMetric: String, CaseIterable {
    case primary
    case lean
    case muscle
    case fat
    case visceral
    case subcutaneous
    case bone

    var color: Color {
        switch self {
        case .primary: .formaChartPrimary
        case .lean, .muscle: .formaChartMuscle
        case .fat: .formaChartFat
        case .visceral: .formaChartVisceral
        case .subcutaneous: .formaChartSubcutaneous
        case .bone: .formaChartBone
        }
    }

    static func infer(from label: String) -> FormaChartMetric {
        let label = label.lowercased()
        if label.contains("visceral") { return .visceral }
        if label.contains("subcutaneous") { return .subcutaneous }
        if label.contains("muscle") { return .muscle }
        if label.contains("lean") { return .lean }
        if label.contains("bone") { return .bone }
        if label.contains("fat") { return .fat }
        return .primary
    }
}

enum FormaChartStyle {
    /// Minimal utility charts — one accent series, quiet axes.
    static let lineStyle = StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
    static let gridLineStyle = StrokeStyle(lineWidth: 0.5, lineCap: .round, dash: [2, 5])
    static let gridOpacity = 0.08
    static let axisLabelOpacity = 0.45
    static let endpointSize: CGFloat = 7
    static let compactHeight: CGFloat = 168
    static let expandedHeight: CGFloat = 210

    static func areaGradient(_ color: Color) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: color.opacity(0.16), location: 0),
                .init(color: color.opacity(0.05), location: 0.55),
                .init(color: color.opacity(0), location: 1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static func paddedDomain(values: [Double], includeZero: Bool = false) -> ClosedRange<Double> {
        guard var lower = values.min(), var upper = values.max() else { return 0...1 }
        if includeZero {
            lower = min(0, lower)
            upper = max(0, upper)
        }
        let spread = upper - lower
        let padding = max(abs(upper) * 0.04, spread == 0 ? max(abs(upper) * 0.08, 1) : spread * 0.12)
        return (lower - padding)...(upper + padding)
    }

    static func axisDates(_ dates: [Date]) -> [Date] {
        let sorted = Array(Set(dates)).sorted()
        guard sorted.count > 2 else { return sorted }
        return [sorted[0], sorted[sorted.count / 2], sorted[sorted.count - 1]]
    }

    static func nearestDate(to selection: Date?, in dates: [Date]) -> Date? {
        guard let selection else { return dates.max() }
        return dates.min { abs($0.timeIntervalSince(selection)) < abs($1.timeIntervalSince(selection)) }
    }

    static func steppedDate(from current: Date?, offset: Int, in dates: [Date]) -> Date? {
        let samples = Array(Set(dates)).sorted()
        guard !samples.isEmpty else { return nil }
        let currentDate = nearestDate(to: current, in: samples) ?? samples[samples.count - 1]
        let currentIndex = samples.firstIndex(of: currentDate) ?? (samples.count - 1)
        return samples[min(max(currentIndex + offset, 0), samples.count - 1)]
    }
}

struct FormaChartSummaryItem: Identifiable {
    let id: String
    let label: String
    let value: String
    let color: Color

    init(id: String, label: String, value: String, color: Color) {
        self.id = id
        self.label = label
        self.value = value
        self.color = color
    }
}

struct FormaChartFooter: View {
    let date: Date?
    let items: [FormaChartSummaryItem]
    var prefix = "Latest"

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: FormaSpacing.xs) {
                    dateLabel
                    itemScroll
                }
            } else {
                HStack(spacing: FormaSpacing.sm) {
                    dateLabel
                        .frame(width: 58, alignment: .leading)
                    itemScroll
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }

    private var dateLabel: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(prefix)
                .font(FormaTypography.textStyle(.caption2, weight: .semibold))
                .foregroundStyle(.tertiary)
                .textCase(.uppercase)
                .tracking(0.4)

            if let date {
                Text(date.formatted(.dateTime.month(.abbreviated).day()))
                    .font(FormaTypography.textStyle(.caption, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
    }

    private var itemScroll: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FormaSpacing.xs) {
                ForEach(items) { item in
                    HStack(spacing: 5) {
                        Circle().fill(item.color).frame(width: 6, height: 6)
                        Text(item.label)
                            .foregroundStyle(.secondary)
                        Text(item.value)
                            .foregroundStyle(.primary)
                            .fontWeight(.semibold)
                    }
                    .font(FormaTypography.textStyle(.caption))
                    .padding(.horizontal, 9)
                    .frame(minHeight: 30)
                    .background(Color.appSubtleFill, in: Capsule())
                }
            }
        }
    }
}

struct FormaChartEmptyState: View {
    var hasSinglePoint = false

    var body: some View {
        VStack(spacing: FormaSpacing.xs) {
            Image(forma: hasSinglePoint ? "chart.line.uptrend.xyaxis" : "chart.xyaxis.line")
                .font(FormaTypography.textStyle(.title3, weight: .medium))
                .foregroundStyle(Color.secondary)

            Text(hasSinglePoint ? "More readings needed for a trend" : "No history yet")
                .font(FormaTypography.textStyle(.subheadline, weight: .semibold))
                .foregroundStyle(.primary)

            Text(hasSinglePoint ? "Your next reading will start showing change over time." : "Record a measurement to begin this chart.")
                .font(FormaTypography.textStyle(.caption))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: FormaChartStyle.compactHeight)
    }
}

struct FormaChartPoint: Identifiable, Equatable {
    let date: Date
    let value: Double
    let metric: String
    let color: Color

    var id: String { "\(metric)|\(date.timeIntervalSinceReferenceDate)" }

    static func == (lhs: FormaChartPoint, rhs: FormaChartPoint) -> Bool {
        lhs.date == rhs.date
            && lhs.value == rhs.value
            && lhs.metric == rhs.metric
    }
}

/// Immutable chart preparation shared by rendering, selection, and accessibility.
struct FormaChartData {
    let points: [FormaChartPoint]
    let dates: [Date]
    let sampleDates: [Date]
    let domain: ClosedRange<Double>
    let latestDateByMetric: [String: Date]
    let groups: [String: [FormaChartPoint]]

    init(points: [FormaChartPoint], includeZero: Bool = false) {
        let isOrdered = zip(points, points.dropFirst()).allSatisfy { previous, current in
            previous.date < current.date
                || (previous.date == current.date && previous.metric <= current.metric)
        }
        let ordered = isOrdered ? points : points.sorted {
            $0.date == $1.date ? $0.metric < $1.metric : $0.date < $1.date
        }
        self.points = ordered
        dates = ordered.map(\.date)
        sampleDates = Array(Set(dates)).sorted()
        domain = FormaChartStyle.paddedDomain(values: ordered.map(\.value), includeZero: includeZero)
        groups = Dictionary(grouping: ordered, by: \.metric)
        latestDateByMetric = groups.compactMapValues { $0.last?.date }
    }
}

struct FormaTimeSeriesChart: View {
    let points: [FormaChartPoint]
    var unit = ""
    var unitsByMetric: [String: String] = [:]
    var showsSignedValues = false
    var height = FormaChartStyle.compactHeight

    @State private var selectedDate: Date?
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AppStorage(FormaFeedbackPreferences.hapticsKey) private var hapticsEnabled = true

    private let data: [FormaChartPoint]
    private let dates: [Date]
    private let sampleDates: [Date]
    private let domain: ClosedRange<Double>
    private let latestDateByMetric: [String: Date]
    private let groups: [String: [FormaChartPoint]]

    init(
        points: [FormaChartPoint],
        unit: String = "",
        unitsByMetric: [String: String] = [:],
        showsSignedValues: Bool = false,
        includeZero: Bool = false,
        height: CGFloat = FormaChartStyle.compactHeight
    ) {
        self.points = points
        self.unit = unit
        self.unitsByMetric = unitsByMetric
        self.showsSignedValues = showsSignedValues
        self.height = height
        // A selection drag only changes selectedDate; reuse the report's data work.
        let prepared = FormaChartData(points: points, includeZero: includeZero)
        data = prepared.points
        dates = prepared.dates
        sampleDates = prepared.sampleDates
        domain = prepared.domain
        latestDateByMetric = prepared.latestDateByMetric
        groups = prepared.groups
    }

    private var activeDate: Date? { FormaChartStyle.nearestDate(to: selectedDate, in: sampleDates) }
    private var accessibilitySummary: String {
        return groups.keys.sorted().compactMap { metric in
            guard let values = groups[metric],
                  let first = values.first,
                  let last = values.last else {
                return nil
            }

            let direction: String
            if values.count == 1 {
                direction = "one reading"
            } else if last.value > first.value {
                direction = "trending up"
            } else if last.value < first.value {
                direction = "trending down"
            } else {
                direction = "unchanged"
            }

            return "\(metric), latest \(formatted(last.value, metric: metric)), \(direction)"
        }
        .joined(separator: ". ")
    }

    private var accessibilityActiveSummary: String {
        guard let activeDate else { return accessibilitySummary }
        let values = items(on: activeDate)
            .map { "\($0.metric) \(formatted($0.value, metric: $0.metric))" }
            .joined(separator: ", ")
        return "\(activeDate.formatted(.dateTime.month(.wide).day().year())), \(values)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.sm) {
            if data.isEmpty {
                FormaChartEmptyState()
            } else if data.count == 1 {
                FormaChartEmptyState(hasSinglePoint: true)
                FormaDivider()
                summaryFooter
            } else {
                chart
                    .frame(height: dynamicTypeSize.isAccessibilitySize ? max(height, FormaChartStyle.expandedHeight) : height)
                    .padding(.bottom, FormaSpacing.xxs)

                FormaDivider()

                summaryFooter
            }
        }
        .padding(FormaSpacing.md)
        .formaSurface(.chart, padding: nil)
        // Charts are expensive to interpolate — never inherit tab-switch animations.
        .transaction { $0.animation = nil }
        .onChange(of: points) { _, newPoints in
            guard let selectedDate else { return }
            if newPoints.isEmpty || !newPoints.contains(where: { $0.date == selectedDate }) {
                self.selectedDate = nil
            }
        }
        .sensoryFeedback(.selection, trigger: activeDate) { oldDate, newDate in
            hapticsEnabled && newDate != nil && oldDate != newDate
        }
    }

    private var chart: some View {
        // Capture derived values once: mark closures run once per sample.
        let data = data
        let domain = domain
        let latestDateByMetric = latestDateByMetric
        let activeDate = activeDate
        return Chart {
            ForEach(data) { item in
                AreaMark(
                    x: .value("Date", item.date),
                    yStart: .value("Baseline", domain.lowerBound),
                    yEnd: .value("Value", item.value),
                    series: .value("Metric", item.metric)
                )
                .foregroundStyle(FormaChartStyle.areaGradient(item.color))
                .interpolationMethod(.monotone)
            }

            ForEach(data) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Value", item.value),
                    series: .value("Metric", item.metric)
                )
                .foregroundStyle(item.color)
                .lineStyle(FormaChartStyle.lineStyle)
                .interpolationMethod(.monotone)
            }

            ForEach(data) { item in
                if latestDateByMetric[item.metric] == item.date {
                    PointMark(x: .value("Date", item.date), y: .value("Value", item.value))
                        .foregroundStyle(item.color)
                        .symbol {
                            Circle()
                                .fill(item.color)
                                .frame(width: FormaChartStyle.endpointSize, height: FormaChartStyle.endpointSize)
                                .overlay(Circle().stroke(Color.appChartBackground, lineWidth: 2))
                        }
                }
            }

            if let activeDate, selectedDate != nil {
                RuleMark(x: .value("Selected date", activeDate))
                    .foregroundStyle(Color.secondary.opacity(0.28))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))

                ForEach(items(on: activeDate)) { item in
                    PointMark(x: .value("Selected date", item.date), y: .value("Selected value", item.value))
                        .foregroundStyle(item.color)
                        .symbolSize(42)
                }
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartLegend(.hidden)
        .chartYScale(domain: domain)
        .chartXScale(range: .plotDimension(startPadding: 8, endPadding: 8))
        .chartPlotStyle { plot in
            plot
                .clipped()
                .contentShape(Rectangle())
        }
        .chartXAxis {
            AxisMarks(position: .bottom, values: FormaChartStyle.axisDates(dates)) { _ in
                AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.secondary.opacity(0.20))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(FormaTypography.chartLabel)
                    .foregroundStyle(Color.secondary.opacity(FormaChartStyle.axisLabelOpacity))
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { _ in
                AxisGridLine(stroke: FormaChartStyle.gridLineStyle)
                    .foregroundStyle(Color.secondary.opacity(FormaChartStyle.gridOpacity))
                AxisValueLabel()
                    .font(FormaTypography.chartLabel)
                    .foregroundStyle(Color.secondary.opacity(FormaChartStyle.axisLabelOpacity))
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Measurement trend chart")
        .accessibilityValue(selectedDate == nil ? accessibilitySummary : accessibilityActiveSummary)
        .accessibilityHint("Swipe up or down to inspect readings by date")
        .accessibilityAdjustableAction { direction in
            adjustSelection(direction)
        }
    }

    private var summaryFooter: some View {
        let date = activeDate
        let selectedItems = date.map(items(on:)) ?? []
        return FormaChartFooter(
            date: date,
            items: selectedItems.map {
                FormaChartSummaryItem(
                    id: $0.id,
                    label: $0.metric,
                    value: formatted($0.value, metric: $0.metric),
                    color: $0.color
                )
            },
            prefix: selectedDate == nil ? "Latest" : "Selected"
        )
    }

    private func items(on date: Date) -> [FormaChartPoint] {
        let calendar = Calendar.current
        return data.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func adjustSelection(_ direction: AccessibilityAdjustmentDirection) {
        switch direction {
        case .increment:
            selectedDate = FormaChartStyle.steppedDate(from: activeDate, offset: 1, in: sampleDates)
        case .decrement:
            selectedDate = FormaChartStyle.steppedDate(from: activeDate, offset: -1, in: sampleDates)
        @unknown default:
            break
        }
    }

    private func formatted(_ value: Double, metric: String) -> String {
        let prefix = showsSignedValues && value > 0 ? "+" : ""
        let number = abs(value) >= 100
            ? String(format: "%.0f", value)
            : String(format: "%.2f", value)
        let resolvedUnit = unitsByMetric[metric] ?? unit
        return resolvedUnit.isEmpty ? "\(prefix)\(number)" : "\(prefix)\(number) \(resolvedUnit)"
    }
}
