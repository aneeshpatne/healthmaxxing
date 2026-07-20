import SwiftUI

private extension Color {
    /// Muscle visuals share the app's pastel theme palette.
    static let musclePrimary = Color.sleekAccent
    static let muscleSecondary = Color.formaCyan
    static let musclePositive = Color.formaTeal
    static let muscleCaution = Color.formaAmber
    static let muscleNegative = Color.formaCoral
}

struct MuscleTab: View {
    let payload: InsightReportPayload?

    private var gaugeSection: InsightReportMetricSection? {
        payload?.muscle["skeletal_muscle_gauge"]
    }

    private var trendSections: [InsightReportMetricSection] {
        ["muscle_mass", "bone_mass_trend", "muscle_ratio_trend", "skeletal_muscle_mass_trend"]
            .compactMap { payload?.muscle[$0] }
    }

    private var hasContent: Bool {
        gaugeSection != nil || !trendSections.isEmpty
    }

    var body: some View {
        // Match Fat: only build on-screen metric cards when the tab appears.
        LazyVStack(spacing: FormaSpacing.cardGap) {
            if !hasContent {
                MetricsUnavailableContent(message: "Muscle report data is unavailable.")
            }

            if let section = gaugeSection, section.numberValue != nil {
                SkeletalMuscleGaugeCard(section: section)
            }

            ForEach(Array(trendSections.enumerated()), id: \.offset) { _, section in
                MuscleReportCard(section: section)
            }
        }
        .padding(.horizontal, FormaSpacing.screenGutter)
        .padding(.top, FormaSpacing.xxs)
        .padding(.bottom, FormaSpacing.xl)
    }
}

// MARK: - Skeletal Muscle Gauge

private struct SkeletalMuscleGaugeCard: View {
    let section: InsightReportMetricSection

    private var value: Double {
        min(60, max(20, section.numberValue ?? 38))
    }

    private var accent: Color {
        section.factorColor?.color ?? Color.musclePositive
    }

    private static let gaugeSegments: [FormaGaugeSegment] = [
        FormaGaugeSegment(color: .muscleNegative, min: 20, max: 30),
        FormaGaugeSegment(color: .muscleCaution, min: 30, max: 35),
        FormaGaugeSegment(color: .musclePrimary, min: 35, max: 42),
        FormaGaugeSegment(color: .muscleSecondary, min: 42, max: 50),
        FormaGaugeSegment(color: .musclePositive, min: 50, max: 60)
    ]

    private static let categories: [FormaLegendCategory] = [
        FormaLegendCategory(name: "Low", range: "< 30%", color: .muscleNegative, min: 0, max: 30),
        FormaLegendCategory(name: "Fair", range: "30-35%", color: .muscleCaution, min: 30, max: 35),
        FormaLegendCategory(name: "Good", range: "35-42%", color: .musclePrimary, min: 35, max: 42),
        FormaLegendCategory(name: "Strong", range: "42-50%", color: .muscleSecondary, min: 42, max: 50),
        FormaLegendCategory(name: "Elite", range: "> 50%", color: .musclePositive, min: 50, max: 100)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader(
                section.displayTitle,
                subtitle: section.title
            )

            FormaSemicircularGauge(
                value: value,
                accent: accent,
                segments: Self.gaugeSegments,
                range: 20...60,
                tickLabels: [20, 30, 35, 42, 50, 60],
                valueText: String(format: "%.1f%%", value),
                caption: "SKELETAL MUSCLE"
            )
            .padding(.top, FormaSpacing.xs)

            FormaCategoryLegend(categories: Self.categories, selectedValue: value)
                .padding(.top, FormaSpacing.xxs)

            if !section.displayComment.isEmpty || section.remark != nil {
                FormaDivider()

                FormaCallout(
                    text: section.remark?.text ?? section.displayComment,
                    systemImage: section.remark?.marker?.iconName ?? "figure.strengthtraining.traditional",
                    tint: section.remark?.marker?.color ?? accent
                )
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            "Skeletal muscle ratio, \(String(format: "%.1f", value)) percent. \(section.displayComment)"
        )
    }
}

// MARK: - Trend / section cards

private struct MuscleReportCard: View {
    let section: InsightReportMetricSection

    private var metricTint: Color {
        FormaChartMetric.infer(from: section.displayTitle).color
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader(section.displayTitle) {
                if let value = section.numberValue {
                    FormaValueBadge(text: String(format: "%.1f", value), tint: metricTint)
                }
            }

            VStack(alignment: .leading, spacing: FormaSpacing.xxs) {
                if let title = section.title, title != section.displayTitle {
                    Text(title)
                        .font(FormaTypography.sectionHeadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !section.displayComment.isEmpty {
                    Text(section.displayComment)
                        .font(FormaTypography.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let trendPoints = section.trends.first?.value, !trendPoints.isEmpty {
                let chartPoints = trendPoints.sorted { $0.date < $1.date }

                FormaTimeSeriesChart(
                    points: chartPoints.map {
                        FormaChartPoint(
                            date: $0.date,
                            value: $0.value,
                            metric: section.displayTitle,
                            color: metricTint
                        )
                    }
                )
            }

            if let remark = section.remark {
                FormaDivider()

                FormaCallout(
                    text: remark.text ?? "",
                    systemImage: remark.marker?.iconName ?? "sparkle",
                    tint: remark.marker?.color ?? Color.sleekAccent
                )
            }
        }
        .formaMetricCard()
    }
}
