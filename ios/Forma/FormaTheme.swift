import SwiftUI
import Charts

// MARK: - Foundations

enum FormaSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    static let screenGutter = lg
    static let cardGap = lg
    static let sectionGap = xl
    static let cardInset = lg

    /// Unified vertical rhythm inside cards (header → content → divider → callout).
    static let cardContent = lg
}

enum FormaSemicircularGaugeLayout {
    static let aspectRatio: CGFloat = 2
    static let strokeWidth: CGFloat = 18
    static let labelInset: CGFloat = 30
    static let markerDiameter: CGFloat = 18
    static let markerStrokeWidth: CGFloat = 3.5
    static let scoreOffset: CGFloat = 20
}

enum FormaRadius {
    static let badge: CGFloat = 9
    static let inset: CGFloat = 14
    static let action: CGFloat = 16
    static let card: CGFloat = 22
    static let hero: CGFloat = 28
}

enum FormaTypography {
    static func wordmark(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static let eyebrow = Font.caption.weight(.bold)
    static let cardTitle = Font.system(.headline, design: .rounded).weight(.semibold)
    static let body = Font.subheadline
    static let metricSmall = Font.system(size: 20, weight: .bold, design: .rounded)
    static let metric = Font.system(size: 34, weight: .semibold, design: .rounded)
    static let heroMetric = Font.system(size: 64, weight: .semibold, design: .rounded)
    static let unit = Font.subheadline.weight(.semibold)
    static let chartLabel = Font.caption2.weight(.medium)

    /// 40pt rounded — the large readout centered in semicircular gauges.
    static let gaugeValue = Font.system(size: 40, weight: .bold, design: .rounded)
    /// 10pt — the smallest legible label in the app (legend ranges, dense annotations).
    static let micro = Font.system(size: 10, weight: .medium)
    /// Medium-strength headline used inside cards beneath the card title.
    static let sectionHeadline = Font.body.weight(.medium)
}

// MARK: - Palette

extension Color {
    static let appBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.028, green: 0.037, blue: 0.034, alpha: 1)
            : UIColor(red: 0.955, green: 0.960, blue: 0.956, alpha: 1)
    })

    static let appSecondaryBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.052, green: 0.067, blue: 0.061, alpha: 0.98)
            : UIColor(red: 0.982, green: 0.986, blue: 0.982, alpha: 0.98)
    })

    static let appTertiaryBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.078, green: 0.098, blue: 0.090, alpha: 1)
            : UIColor(red: 0.915, green: 0.930, blue: 0.920, alpha: 1)
    })

    static let appChartBackground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.050, green: 0.062, blue: 0.056, alpha: 1)
            : UIColor(red: 0.935, green: 0.942, blue: 0.937, alpha: 1)
    })

    static let appSeparator = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.065)
            : UIColor(red: 0.08, green: 0.14, blue: 0.11, alpha: 0.07)
    })

    static let appSurfaceHighlight = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.055)
            : UIColor(white: 1, alpha: 0.75)
    })

    static let appSubtleFill = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1, alpha: 0.04)
            : UIColor(red: 0.08, green: 0.16, blue: 0.12, alpha: 0.045)
    })

    /// Vivid spring mint — the primary brand accent.
    static let sleekAccent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.36, green: 0.87, blue: 0.66, alpha: 1)
            : UIColor(red: 0.07, green: 0.56, blue: 0.38, alpha: 1)
    })

    static let actionInk = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.22, green: 0.62, blue: 0.45, alpha: 1)
            : UIColor(red: 0.07, green: 0.38, blue: 0.27, alpha: 1)
    })

    static let actionForeground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.025, green: 0.075, blue: 0.055, alpha: 1)
            : UIColor.white
    })

    /// Vivid teal.
    static let formaTeal = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.28, green: 0.86, blue: 0.71, alpha: 1)
            : UIColor(red: 0.05, green: 0.58, blue: 0.44, alpha: 1)
    })

    /// Vivid coral.
    static let formaCoral = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.97, green: 0.46, blue: 0.45, alpha: 1)
            : UIColor(red: 0.86, green: 0.27, blue: 0.27, alpha: 1)
    })

    /// Vivid gold.
    static let formaAmber = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.98, green: 0.76, blue: 0.31, alpha: 1)
            : UIColor(red: 0.80, green: 0.52, blue: 0.07, alpha: 1)
    })

    /// Vivid sky.
    static let formaCyan = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.33, green: 0.76, blue: 0.95, alpha: 1)
            : UIColor(red: 0.07, green: 0.50, blue: 0.69, alpha: 1)
    })

    /// Soft pastel yellow — a mid-scale status step between amber and teal.
    static let formaYellow = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.85, blue: 0.42, alpha: 1)
            : UIColor(red: 0.70, green: 0.56, blue: 0.04, alpha: 1)
    })

    // MARK: Semantic status aliases — prefer these over raw system colors.

    static let formaPositive = Color.formaTeal
    static let formaCaution = Color.formaAmber
    static let formaNegative = Color.formaCoral
    static let formaInfo = Color.formaCyan

    /// Ring drawn around chart markers. Matches the card surface so markers read
    /// as a clean cutout in both light and dark appearances.
    static let appMarkerRing = Color.appSecondaryBackground

    static let cardShadow = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 0.30)
            : UIColor(red: 0.10, green: 0.09, blue: 0.20, alpha: 0.08)
    })

    static let contactShadow = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0, alpha: 0.22)
            : UIColor(red: 0.08, green: 0.07, blue: 0.16, alpha: 0.05)
    })

    /// A softened, pastel version of the color — used for atmospheric washes so
    /// vivid accents can glow gently without looking washed out elsewhere.
    func pastelized() -> Color {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        guard uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return self
        }

        return Color(uiColor: UIColor(
            hue: hue,
            saturation: max(0, saturation * 0.52),
            brightness: min(1, brightness * 0.72 + 0.26),
            alpha: alpha
        ))
    }
}

// MARK: - Background and surfaces

struct FormaBackground: View {
    /// Optional wash anchored to the top edge, rendered as a pastel tint of the
    /// accent. Rendered behind scrolling content, so it stays fixed while the
    /// page scrolls or refreshes.
    var accent: Color? = nil

    var body: some View {
        ZStack {
            Color.appBackground

            RadialGradient(
                colors: [Color.sleekAccent.opacity(0.035), .clear],
                center: .topLeading,
                startRadius: 0,
                endRadius: 430
            )

            RadialGradient(
                colors: [Color.formaCyan.opacity(0.018), .clear],
                center: .bottomTrailing,
                startRadius: 0,
                endRadius: 520
            )

            if let accent {
                VStack(spacing: 0) {
                    FormaAccentWash(accent: accent)

                    Spacer(minLength: 0)
                }
                .transition(.opacity)
            }
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Colored wash used at the top of a page. It can live either in the fixed
/// app background or inside scroll content when it should move with the page.
struct FormaAccentWash: View {
    let accent: Color

    var body: some View {
        let pastel = accent.pastelized()

        LinearGradient(
            colors: [
                pastel.opacity(0.30),
                pastel.opacity(0.11),
                .clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 420)
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

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: style.radius, style: .continuous)

        Group {
            if let padding {
                content.padding(padding)
            } else {
                content
            }
        }
        .background {
            if style == .inset || style == .chart {
                shape.fill(style.fill)
            } else {
                let base = shape
                    .fill(style.fill)
                    .overlay {
                        // Soft top-down sheen for a premium, lit-from-above surface.
                        shape.fill(
                            LinearGradient(
                                colors: [
                                    Color.appSurfaceHighlight.opacity(0.5),
                                    Color.appSurfaceHighlight.opacity(0.06),
                                    .clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                    .overlay {
                        if let tint {
                            // Atmospheric wash anchoring the card to its status color.
                            shape.fill(
                                LinearGradient(
                                    colors: [tint.opacity(0.14), tint.opacity(0.04), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                    }

                if let tint {
                    base
                        .shadow(color: tint.opacity(0.22), radius: 24, x: 0, y: 12)
                        .shadow(color: Color.cardShadow, radius: 16, x: 0, y: 8)
                        .shadow(color: Color.contactShadow, radius: 2, x: 0, y: 1)
                } else {
                    base
                        .shadow(
                            color: Color.cardShadow,
                            radius: style == .floating ? 24 : (style == .hero ? 20 : 14),
                            x: 0,
                            y: style == .floating ? 12 : (style == .hero ? 10 : 7)
                        )
                        .shadow(
                            color: Color.contactShadow,
                            radius: style == .floating ? 3 : 2,
                            x: 0,
                            y: 1
                        )
                }
            }
        }
        .overlay {
            shape.strokeBorder(
                LinearGradient(
                    colors: [tint?.opacity(0.35) ?? Color.appSurfaceHighlight, Color.appSeparator],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.5
            )
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
        HStack(alignment: subtitle == nil ? .center : .top, spacing: FormaSpacing.sm) {
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(FormaTypography.cardTitle)
                    .tracking(-0.2)
                    .foregroundStyle(.primary)

                if let subtitle, !subtitle.isEmpty, subtitle != title {
                    Text(subtitle)
                        .font(FormaTypography.body)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Spacer(minLength: FormaSpacing.xs)
            trailing
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
struct FormaValueBadge: View {
    let text: String
    var tint: Color = .sleekAccent

    var body: some View {
        Text(text)
            .font(.subheadline.weight(.bold))
            .monospacedDigit()
            .foregroundStyle(tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(tint.opacity(0.13), in: Capsule())
            .overlay {
                Capsule().strokeBorder(tint.opacity(0.18), lineWidth: 0.5)
            }
    }
}

/// Small tinted tile used to present an SF Symbol alongside text.
struct FormaIconTile: View {
    let systemImage: String
    var tint: Color = .sleekAccent
    var size: CGFloat = 30
    var radius: CGFloat = FormaRadius.badge
    var symbolFont: Font = .system(size: 13, weight: .semibold)

    var body: some View {
        Image(systemName: systemImage)
            .font(symbolFont)
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(tint.opacity(0.12))
                    .overlay {
                        RoundedRectangle(cornerRadius: radius, style: .continuous)
                            .strokeBorder(tint.opacity(0.14), lineWidth: 0.5)
                    }
            }
    }
}

struct FormaCallout: View {
    let text: String
    var systemImage = "sparkles"
    var tint: Color = .sleekAccent

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

    var body: some View {
        VStack(spacing: FormaSpacing.lg) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.11))
                    .frame(width: 64, height: 64)

                Circle()
                    .strokeBorder(tint.opacity(0.14), lineWidth: 0.5)
                    .frame(width: 64, height: 64)

                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(spacing: FormaSpacing.xs) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)

                Text(message)
                    .font(FormaTypography.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let actionTitle, let action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.glass)
                .buttonBorderShape(.capsule)
                .tint(actionTint ?? tint)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, FormaSpacing.xl)
        .padding(.vertical, 80)
    }
}

// MARK: - Transitions

enum FormaTransition {
    /// Gentle rise-and-fade used when cards and screens swap content.
    static let card: AnyTransition = .opacity.combined(with: .offset(y: 10))
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
                        .font(.caption2.weight(.semibold))
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
                        .font(.caption.weight(.bold))
                        .foregroundStyle(captionColor)
                        .tracking(0.6)
                }
                .position(x: width / 2, y: height - FormaSemicircularGaugeLayout.scoreOffset)
            }
        }
        .aspectRatio(FormaSemicircularGaugeLayout.aspectRatio, contentMode: .fit)
        .onAppear { animateToValue() }
        .onChange(of: value) { _, _ in animateToValue() }
    }

    private func animateToValue() {
        let clamped = min(range.upperBound, max(range.lowerBound, value))

        if reduceMotion {
            animatedValue = clamped
        } else {
            withAnimation(.easeOut(duration: 0.7)) {
                animatedValue = clamped
            }
        }
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

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<categories.count, id: \.self) { index in
                let cat = categories[index]
                let isSelected = selectedValue >= cat.min && selectedValue < cat.max

                VStack(spacing: 6) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(isSelected ? AnyShapeStyle(cat.color.gradient) : AnyShapeStyle(cat.color.opacity(0.15)))
                        .frame(height: 4)

                    Text(cat.name)
                        .font(.caption2.weight(isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? .primary : .secondary)
                        .minimumScaleFactor(0.8)
                        .lineLimit(1)

                    Text(cat.range)
                        .font(FormaTypography.micro)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Skeleton loading

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .modifier(AnimatedShimmerModifier(phase: reduceMotion ? 0.5 : phase))
            .onAppear {
                guard !reduceMotion else { return }

                withAnimation(.linear(duration: 1.6).repeatForever(autoreverses: false)) {
                    phase = 1
                }
            }
    }
}

struct AnimatedShimmerModifier: AnimatableModifier {
    var phase: CGFloat

    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    let w = geo.size.width
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.3),
                            .init(color: .white.opacity(0.22), location: 0.5),
                            .init(color: .clear, location: 0.7)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: w * 2)
                    .offset(x: -w + (w * 2 * phase))
                    .blendMode(.overlay)
                }
                .mask(content)
            )
    }
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

struct FormaSkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.lg) {
            VStack(alignment: .leading, spacing: FormaSpacing.xs) {
                FormaSkeletonBlock(width: 150, height: 18, opacity: 0.14)
                FormaSkeletonBlock(width: 230, height: 13, opacity: 0.08)
            }

            FormaSkeletonBlock(height: 150, radius: FormaRadius.inset, opacity: 0.05)

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
        case .primary: .sleekAccent
        case .lean, .muscle: .formaTeal
        case .fat: .formaCoral
        case .visceral: .formaAmber
        case .subcutaneous: .formaCyan
        case .bone: .secondary
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
    static let lineStyle = StrokeStyle(lineWidth: 2.25, lineCap: .round, lineJoin: .round)
    static let gridLineStyle = StrokeStyle(lineWidth: 0.5, lineCap: .round, dash: [2, 4])
    static let gridOpacity = 0.12
    static let axisLabelOpacity = 0.52
    static let endpointSize: CGFloat = 8
    static let compactHeight: CGFloat = 176
    static let expandedHeight: CGFloat = 220

    static func areaGradient(_ color: Color) -> LinearGradient {
        LinearGradient(
            stops: [
                .init(color: color.opacity(0.24), location: 0),
                .init(color: color.opacity(0.08), location: 0.58),
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

    var body: some View {
        HStack(spacing: FormaSpacing.sm) {
            VStack(alignment: .leading, spacing: 2) {
                Text(prefix)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)
                    .tracking(0.4)

                if let date {
                    Text(date.formatted(.dateTime.month(.abbreviated).day()))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: 58, alignment: .leading)

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
                        .font(.caption)
                        .padding(.horizontal, 9)
                        .frame(height: 30)
                        .background(Color.appSubtleFill, in: Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
    }
}

struct FormaChartEmptyState: View {
    var hasSinglePoint = false

    var body: some View {
        VStack(spacing: FormaSpacing.xs) {
            Image(systemName: hasSinglePoint ? "chart.line.uptrend.xyaxis" : "chart.xyaxis.line")
                .font(.title3.weight(.medium))
                .foregroundStyle(Color.sleekAccent)

            Text(hasSinglePoint ? "More readings needed for a trend" : "No history yet")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(hasSinglePoint ? "Your next reading will start showing change over time." : "Record a measurement to begin this chart.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: FormaChartStyle.compactHeight)
    }
}

struct FormaChartPoint: Identifiable {
    let date: Date
    let value: Double
    let metric: String
    let color: Color

    var id: String { "\(metric)|\(date.timeIntervalSinceReferenceDate)" }
}

struct FormaTimeSeriesChart: View {
    let points: [FormaChartPoint]
    var unit = ""
    var includeZero = false
    var height = FormaChartStyle.compactHeight

    @State private var selectedDate: Date?

    private var data: [FormaChartPoint] {
        points.sorted {
            $0.date == $1.date ? $0.metric < $1.metric : $0.date < $1.date
        }
    }

    private var dates: [Date] { data.map(\.date) }
    private var activeDate: Date? { FormaChartStyle.nearestDate(to: selectedDate, in: dates) }
    private var domain: ClosedRange<Double> {
        FormaChartStyle.paddedDomain(values: data.map(\.value), includeZero: includeZero)
    }
    private var latestDateByMetric: [String: Date] {
        Dictionary(grouping: data, by: \.metric).compactMapValues { $0.map(\.date).max() }
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
                    .frame(height: height)
                    .padding(.bottom, FormaSpacing.xxs)

                FormaDivider()

                summaryFooter
            }
        }
        .padding(FormaSpacing.md)
        .formaSurface(.chart, padding: nil)
        .onChange(of: points.map(\.id)) { _, ids in
            guard let selectedDate else { return }
            if !points.contains(where: { $0.date == selectedDate }) || ids.isEmpty {
                self.selectedDate = nil
            }
        }
    }

    private var chart: some View {
        Chart {
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
                                .overlay(Circle().stroke(Color.appTertiaryBackground, lineWidth: 2))
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
            AxisMarks(position: .bottom, values: FormaChartStyle.axisDates(dates)) { value in
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
                    value: formatted($0.value),
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

    private func formatted(_ value: Double) -> String {
        let number = abs(value) >= 100 ? String(format: "%.0f", value) : String(format: "%.1f", value)
        return unit.isEmpty ? number : "\(number) \(unit)"
    }
}
