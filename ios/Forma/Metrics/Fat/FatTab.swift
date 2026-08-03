import SwiftUI

struct FatRatioMetrics {
    let value: Double

    var valueText: String {
        String(format: "%.1f%%", value)
    }

    var statusText: String {
        if value < 6.0 {
            return "Low / Essential"
        } else if value < 18.0 {
            return "Optimal"
        } else if value < 25.0 {
            return "Average"
        } else {
            return "High Fat Ratio"
        }
    }

    var verdictText: String {
        if value < 6.0 {
            return "Low"
        } else if value < 18.0 {
            return "Good"
        } else if value < 25.0 {
            return "Average"
        } else {
            return "Elevated"
        }
    }

    var statusColor: Color {
        if value < 6.0 {
            return Color.formaNegative
        } else if value < 18.0 {
            return Color.formaPositive
        } else if value < 25.0 {
            return Color.formaCaution
        } else {
            return Color.formaNegative
        }
    }

    var statusIcon: String {
        if value < 6.0 {
            return "exclamationmark.triangle.fill"
        } else if value < 18.0 {
            return "checkmark.circle.fill"
        } else if value < 25.0 {
            return "info.circle.fill"
        } else {
            return "exclamationmark.triangle.fill"
        }
    }
}

struct FatTab: View {
    let payload: InsightReportPayload?

    var body: some View {
        // LazyVStack defers off-screen charts so switching to Fat only builds
        // the cards that fit the first screen instead of every trend at once.
        LazyVStack(spacing: FormaSpacing.cardGap) {
            if payload?.fat.isEmpty != false {
                MetricsUnavailableContent(message: "Fat report data is unavailable.")
            }

            if let section = payload?.fat["fat_ratio"], let value = section.numberValue {
                FatRatioCard(
                    value: value,
                    comment: section.comment,
                    remark: section.remark
                )
                .formaEntrance()
            }

            if let section = payload?.fat["visceral_vs_subcutaneous"],
               let visceralFat = section.firstNestedNumber(
                   "visceralFatIndexDelta",
                   "visceralFatDeltaKg"
               ),
               let subcutaneousFat = section.nestedNumber("subcutaneousFatDeltaKg") {
                let usesIndex = section.nestedNumber("visceralFatIndexDelta") != nil
                VisceralSubcutaneousCard(
                    visceralFat: visceralFat,
                    subcutaneousFat: subcutaneousFat,
                    visceralUnit: usesIndex ? "idx" : "kg",
                    verdict: section.title ?? section.displayTitle,
                    remark: section.remark,
                    comment: section.comment
                )
            }

            if let section = payload?.fat["visceral_trend"], let currentMass = section.numberValue {
                let trendPoints = section.trendPoints(preferredKeys: [
                    "visceralFatIndex",
                    "visceralFatKg",
                    "visceral_fat_kg",
                    "visceralFatMassKg"
                ])
                let usesIndex = section.trends["visceralFatIndex"]?.isEmpty == false
                let unit = usesIndex ? "idx" : "kg"
                FatTrendCard(
                    title: usesIndex ? "Visceral Fat Index" : "Visceral Fat Mass",
                    subtitle: section.comment,
                    valueText: String(format: "%.1f %@", currentMass, unit),
                    unit: unit,
                    color: .formaChartVisceral,
                    metricLabel: "Visceral fat",
                    statusText: section.title ?? section.displayTitle,
                    statusColor: section.remark?.marker?.color ?? .secondary,
                    statusIcon: section.remark?.marker?.iconName ?? "info.circle.fill",
                    remark: section.remark,
                    points: chartPoints(from: trendPoints, metric: "Visceral fat", color: .formaChartVisceral)
                )
            }

            if let section = payload?.fat["subcutaneous_fat_mass_trend"], let currentMass = section.numberValue {
                FatTrendCard(
                    title: "Subcutaneous Fat Mass",
                    subtitle: section.comment,
                    valueText: String(format: "%.1f kg", currentMass),
                    unit: "kg",
                    color: .formaChartSubcutaneous,
                    metricLabel: "Subcutaneous fat",
                    statusText: section.title ?? section.displayTitle,
                    statusColor: section.remark?.marker?.color ?? .secondary,
                    statusIcon: section.remark?.marker?.iconName ?? "info.circle.fill",
                    remark: section.remark,
                    points: chartPoints(
                        from: section.trendPoints(preferredKeys: [
                            "subcutaneousFatKg",
                            "subcutaneous_fat_kg",
                            "subcutaneousFatMassKg"
                        ]),
                        metric: "Subcutaneous fat",
                        color: .formaChartSubcutaneous
                    )
                )
            }

            if let section = payload?.fat["fat_mass_trend"], let currentMass = section.numberValue {
                FatTrendCard(
                    title: "Fat Mass History",
                    subtitle: section.comment,
                    valueText: String(format: "%.1f kg", currentMass),
                    unit: "kg",
                    color: .formaChartFat,
                    metricLabel: "Fat mass",
                    statusText: section.title ?? section.displayTitle,
                    statusColor: section.remark?.marker?.color ?? .secondary,
                    statusIcon: section.remark?.marker?.iconName ?? "chart.line.downtrend.xyaxis",
                    remark: section.remark,
                    points: chartPoints(
                        from: section.trendPoints(preferredKeys: ["fatMassKg", "fat_mass_kg", "totalFatKg"]),
                        metric: "Fat mass",
                        color: .formaChartFat
                    )
                )
            }

            if let section = payload?.fat["fat_ratio_trend"], let value = section.numberValue {
                let metrics = FatRatioMetrics(value: value)
                FatTrendCard(
                    title: "Fat Ratio History",
                    subtitle: section.comment,
                    valueText: String(format: "%.1f%%", value),
                    unit: "%",
                    color: .formaChartFat,
                    metricLabel: "Body fat",
                    statusText: metrics.statusText,
                    statusColor: metrics.statusColor,
                    statusIcon: metrics.statusIcon,
                    remark: section.remark,
                    points: chartPoints(
                        from: section.trends["fatPercent"] ?? [],
                        metric: "Body fat",
                        color: .formaChartFat
                    ),
                    accessibilitySummary: "Fat Ratio, \(String(format: "%.1f", value)) percent, \(metrics.statusText.lowercased()), \(metrics.verdictText.lowercased())."
                )
            }
        }
        .padding(.horizontal, FormaSpacing.screenGutter)
        .padding(.top, FormaSpacing.xxs)
        .padding(.bottom, FormaSpacing.xl)
    }

    private func chartPoints(
        from points: [InsightReportTrendPoint],
        metric: String,
        color: Color
    ) -> [FormaChartPoint] {
        points
            .sorted { $0.date < $1.date }
            .map { FormaChartPoint(date: $0.date, value: $0.value, metric: metric, color: color) }
    }
}

private extension InsightReportMetricSection {
    func trendPoints(preferredKeys: [String]) -> [InsightReportTrendPoint] {
        for key in preferredKeys {
            if let points = trends[key], !points.isEmpty {
                return points
            }
        }

        return trends.values.first(where: { !$0.isEmpty }) ?? []
    }

    func firstNestedNumber(_ keys: String...) -> Double? {
        for key in keys {
            if let number = nestedNumber(key) {
                return number
            }
        }
        return nil
    }
}

// MARK: - Fat Ratio Card

struct FatRatioCard: View {
    let value: Double
    var comment: String? = nil
    var remark: InsightReportRemark? = nil

    var metrics: FatRatioMetrics {
        FatRatioMetrics(value: value)
    }

    private static let gaugeSegments: [FormaGaugeSegment] = [
        FormaGaugeSegment(color: .formaNegative, min: 2, max: 6),
        FormaGaugeSegment(color: .formaPositive, min: 6, max: 18),
        FormaGaugeSegment(color: .formaCaution, min: 18, max: 25),
        FormaGaugeSegment(color: .formaNegative, min: 25, max: 30)
    ]

    private static let categories: [FormaLegendCategory] = [
        FormaLegendCategory(name: "Low", range: "< 6%", color: .formaNegative, min: 0, max: 6),
        FormaLegendCategory(name: "Optimal", range: "6-18%", color: .formaPositive, min: 6, max: 18),
        FormaLegendCategory(name: "Average", range: "18-25%", color: .formaCaution, min: 18, max: 25),
        FormaLegendCategory(name: "High", range: "> 25%", color: .formaNegative, min: 25, max: 100)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader("Body Fat Ratio", subtitle: comment)

            FormaSemicircularGauge(
                value: value,
                accent: metrics.statusColor,
                segments: Self.gaugeSegments,
                range: 2...30,
                tickLabels: [2, 6, 18, 25, 30],
                labelSuffix: "%",
                valueText: metrics.valueText,
                caption: metrics.statusText.uppercased(),
                captionColor: metrics.statusColor
            )
            .padding(.top, FormaSpacing.xs)

            FormaCategoryLegend(categories: Self.categories, selectedValue: value)
                .padding(.top, FormaSpacing.xxs)

            if let text = remark?.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                FormaDivider()
                FormaCallout(
                    text: text,
                    systemImage: remark?.marker?.iconName ?? metrics.statusIcon,
                    tint: remark?.marker?.color ?? metrics.statusColor
                )
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fat Ratio, \(String(format: "%.1f", value)) percent, \(metrics.statusText.lowercased()), \(metrics.verdictText.lowercased()).")
    }
}

// MARK: - Shared fat trend card

/// One card layout for every fat trend: header with trailing value badge, a
/// time-series chart, and an optional tinted remark.
private struct FatTrendCard: View {
    let title: String
    var subtitle: String? = nil
    let valueText: String
    let unit: String
    let color: Color
    let metricLabel: String
    var statusText: String
    var statusColor: Color
    var statusIcon: String
    var remark: InsightReportRemark?
    /// Pre-sorted chart points (built once by `FatTab`).
    let points: [FormaChartPoint]
    var accessibilitySummary: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader(title, subtitle: subtitle) {
                FormaValueBadge(text: valueText, tint: color)
            }

            FormaTimeSeriesChart(
                points: points,
                unit: unit
            )

            if let text = remark?.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                FormaDivider()
                FormaCallout(
                    text: text,
                    systemImage: remark?.marker?.iconName ?? statusIcon,
                    tint: remark?.marker?.color ?? statusColor
                )
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary ?? "\(title) history, ending at \(valueText). Current status is \(statusText). Remark: \((remark?.text ?? "").replacingOccurrences(of: "\n", with: " ")).")
    }
}

// MARK: - Visceral vs Subcutaneous Fat Card

struct VisceralSubcutaneousDonutChart: View {
    let visceralFraction: Double

    var body: some View {
        ZStack {
            let gapOffset: CGFloat = 0.008
            let visceralTrimEnd = max(gapOffset, CGFloat(visceralFraction) - gapOffset)
            let subcutaneousTrimStart = min(1.0 - gapOffset, CGFloat(visceralFraction) + gapOffset)

            // Subcutaneous segment (chart categorical — info family)
            Circle()
                .trim(from: subcutaneousTrimStart, to: 1.0 - gapOffset)
                .stroke(
                    Color.formaChartSubcutaneous.gradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            // Visceral segment (chart categorical — caution family)
            Circle()
                .trim(from: gapOffset, to: visceralTrimEnd)
                .stroke(
                    Color.formaChartVisceral.gradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))

            Text("VS")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
        }
        .frame(width: 72, height: 72)
    }
}

struct VisceralSubcutaneousCard: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    let visceralFat: Double
    let subcutaneousFat: Double
    /// Unit label for visceral (server now sends index deltas as `idx`, legacy was `kg`).
    var visceralUnit: String = "kg"
    let verdict: String
    let remark: InsightReportRemark?
    let comment: String?

    var totalFat: Double {
        visceralFat + subcutaneousFat
    }

    var visceralFraction: Double {
        guard totalFat > 0 else { return 0.0 }
        return visceralFat / totalFat
    }

    var subcutaneousFraction: Double {
        guard totalFat > 0 else { return 0.0 }
        return subcutaneousFat / totalFat
    }

    var visceralPercentageText: String {
        String(format: "%.0f%%", visceralFraction * 100)
    }

    var subcutaneousPercentageText: String {
        String(format: "%.0f%%", subcutaneousFraction * 100)
    }

    private func comparisonMetric(
        title: String,
        value: Double,
        unit: String,
        percentage: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.center)

            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    metricValue(value, tint: tint)
                    metricUnit(unit)
                }
                .fixedSize(horizontal: true, vertical: false)

                VStack(spacing: 1) {
                    metricValue(value, tint: tint)
                    metricUnit(unit)
                }
            }

            Text(percentage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func metricValue(_ value: Double, tint: Color) -> some View {
        Text(String(format: "%.1f", value))
            .font(FormaTypography.metricSmall)
            .foregroundStyle(tint)
    }

    private func metricUnit(_ unit: String) -> some View {
        Text(unit)
            .font(.caption2.weight(.medium))
            .foregroundStyle(.secondary)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader("Visceral vs Subcutaneous", subtitle: comment)

            // Comparison panel
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(spacing: FormaSpacing.md) {
                        comparisonMetric(
                            title: visceralUnit == "idx" ? "Visceral Index" : "Visceral Fat",
                            value: visceralFat,
                            unit: visceralUnit,
                            percentage: visceralPercentageText,
                            tint: Color.formaChartVisceral
                        )

                        VisceralSubcutaneousDonutChart(visceralFraction: visceralFraction)

                        comparisonMetric(
                            title: "Subcutaneous Fat",
                            value: subcutaneousFat,
                            unit: "kg",
                            percentage: subcutaneousPercentageText,
                            tint: Color.formaChartSubcutaneous
                        )
                    }
                } else {
                    HStack(spacing: FormaSpacing.md) {
                        comparisonMetric(
                            title: visceralUnit == "idx" ? "Visceral Index" : "Visceral Fat",
                            value: visceralFat,
                            unit: visceralUnit,
                            percentage: visceralPercentageText,
                            tint: Color.formaChartVisceral
                        )

                        VisceralSubcutaneousDonutChart(visceralFraction: visceralFraction)

                        comparisonMetric(
                            title: "Subcutaneous Fat",
                            value: subcutaneousFat,
                            unit: "kg",
                            percentage: subcutaneousPercentageText,
                            tint: Color.formaChartSubcutaneous
                        )
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, FormaSpacing.xs)
            .formaSurface(.chart, padding: nil)

            if let text = remark?.text ?? comment,
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                FormaDivider()

                FormaCallout(
                    text: text,
                    systemImage: remark?.marker?.iconName ?? "info.circle",
                    tint: remark?.marker?.color ?? .secondary
                )
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Visceral \(String(format: "%.1f", visceralFat)) \(visceralUnit), \(visceralPercentageText). Subcutaneous fat \(String(format: "%.1f", subcutaneousFat)) kilograms, \(subcutaneousPercentageText). Verdict: \(verdict). Remark: \((remark?.text ?? "").replacingOccurrences(of: "\n", with: " ")).")
    }
}

// MARK: - Previews

#Preview {
    ScrollView {
        FatTab(payload: nil)
    }
    .background(Color.appBackground)
}
