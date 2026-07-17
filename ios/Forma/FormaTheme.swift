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
    static let cardGap = md
    static let sectionGap = xl
    static let cardInset = lg
}

enum FormaSemicircularGaugeLayout {
    static let aspectRatio: CGFloat = 2
    static let strokeWidth: CGFloat = 20
    static let labelInset: CGFloat = 30
    static let markerDiameter: CGFloat = 18
    static let markerStrokeWidth: CGFloat = 3.5
    static let scoreOffset: CGFloat = 20
    static let valueFontSize: CGFloat = 40
}

enum FormaRadius {
    static let badge: CGFloat = 8
    static let inset: CGFloat = 14
    static let action: CGFloat = 16
    static let card: CGFloat = 18
    static let hero: CGFloat = 24
}

enum FormaTypography {
    static func wordmark(size: CGFloat) -> Font {
        .system(size: size, weight: .medium, design: .default)
    }

    static let eyebrow = Font.caption.weight(.bold)
    static let cardTitle = Font.headline.weight(.semibold)
    static let body = Font.subheadline
    static let metric = Font.system(size: 34, weight: .semibold, design: .rounded)
    static let heroMetric = Font.system(size: 64, weight: .semibold, design: .rounded)
    static let unit = Font.subheadline.weight(.semibold)
    static let chartLabel = Font.caption2.weight(.medium)
}

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

    static let sleekAccent = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.48, green: 0.67, blue: 0.60, alpha: 1)
            : UIColor(red: 0.20, green: 0.45, blue: 0.38, alpha: 1)
    })

    static let actionInk = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.39, green: 0.56, blue: 0.50, alpha: 1)
            : UIColor(red: 0.10, green: 0.20, blue: 0.17, alpha: 1)
    })

    static let actionForeground = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.035, green: 0.050, blue: 0.045, alpha: 1)
            : UIColor.white
    })

    static let formaTeal = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.43, green: 0.66, blue: 0.58, alpha: 1)
            : UIColor(red: 0.13, green: 0.46, blue: 0.37, alpha: 1)
    })

    static let formaCoral = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.82, green: 0.47, blue: 0.45, alpha: 1)
            : UIColor(red: 0.68, green: 0.25, blue: 0.25, alpha: 1)
    })

    static let formaAmber = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.75, green: 0.63, blue: 0.39, alpha: 1)
            : UIColor(red: 0.62, green: 0.43, blue: 0.13, alpha: 1)
    })

    static let formaCyan = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.47, green: 0.65, blue: 0.70, alpha: 1)
            : UIColor(red: 0.19, green: 0.45, blue: 0.52, alpha: 1)
    })

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
}

// MARK: - Background and surfaces

struct FormaBackground: View {
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
        }
        .ignoresSafeArea()
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
                shape
                    .fill(style.fill)
                    .shadow(
                        color: Color.cardShadow,
                        radius: style == .floating ? 22 : (style == .hero ? 18 : 12),
                        x: 0,
                        y: style == .floating ? 11 : (style == .hero ? 9 : 6)
                    )
                    .shadow(
                        color: Color.contactShadow,
                        radius: style == .floating ? 3 : 2,
                        x: 0,
                        y: 1
                    )
            }
        }
        .overlay {
            shape.strokeBorder(
                LinearGradient(
                    colors: [Color.appSurfaceHighlight, Color.appSeparator],
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
        padding: CGFloat? = FormaSpacing.cardInset
    ) -> some View {
        modifier(FormaSurfaceModifier(style: style, padding: padding))
    }

    func formaMetricCard(padding: CGFloat = FormaSpacing.cardInset) -> some View {
        formaSurface(.card, padding: padding)
    }
}

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
                    .foregroundStyle(.primary)

                if let subtitle, !subtitle.isEmpty, subtitle != title {
                    Text(subtitle)
                        .font(FormaTypography.body)
                        .foregroundStyle(.secondary)
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

struct FormaCallout: View {
    let text: String
    var systemImage = "sparkles"
    var tint: Color = .sleekAccent

    var body: some View {
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            HStack(alignment: .top, spacing: FormaSpacing.sm) {
                Image(systemName: systemImage)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

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
                .init(color: color.opacity(0.16), location: 0),
                .init(color: color.opacity(0.055), location: 0.58),
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
                Rectangle()
                    .fill(Color.appSeparator)
                    .frame(height: 0.5)
                summaryFooter
            } else {
                chart
                    .frame(height: height)
                    .padding(.bottom, FormaSpacing.xxs)

                Rectangle()
                    .fill(Color.appSeparator)
                    .frame(height: 0.5)

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
