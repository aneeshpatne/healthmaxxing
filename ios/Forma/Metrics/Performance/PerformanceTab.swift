import SwiftUI
import Charts

private extension Color {
    /// Performance visuals share the app's pastel theme palette.
    static let performancePrimary = Color.sleekAccent
    static let performanceSecondary = Color.formaCyan
    static let performancePositive = Color.formaTeal
    static let performanceCaution = Color.formaAmber
    static let performanceNegative = Color.formaCoral
}

private extension InsightReportMetricSection {
    var hasWeightComparisonData: Bool {
        firstNumber("currentWeightKg", "currentWeight") != nil
            && firstNumber("targetWeightKg", "targetWeight") != nil
    }

    var hasLeanFatVectorData: Bool {
        let initialWeight = firstNumber("initialWeightKg", "initialWeight", "startWeightKg", "startWeight")
        let currentWeight = firstNumber("currentWeightKg", "currentWeight")
        let targetWeight = firstNumber("targetWeightKg", "targetWeight")
        let initialFat = compositionNumber("initial", "fatMassKg") ?? firstNumber("initialFatKg", "initialFatMassKg", "startFatKg", "startFatMassKg")
        let currentFat = compositionNumber("current", "fatMassKg") ?? firstNumber("currentFatKg", "currentFatMassKg", "totalFatKg")
        let targetFat = compositionNumber("target", "fatMassKg") ?? firstNumber("targetFatKg", "targetFatMassKg")
        let initialLean = compositionNumber("initial", "leanMassKg") ?? firstNumber("initialLeanKg", "initialLeanMassKg", "startLeanKg", "startLeanMassKg") ?? derivedLean(weight: initialWeight, fat: initialFat)
        let currentLean = compositionNumber("current", "leanMassKg") ?? firstNumber("currentLeanKg", "currentLeanMassKg", "totalLeanKg") ?? derivedLean(weight: currentWeight, fat: currentFat)
        let targetLean = compositionNumber("target", "leanMassKg") ?? firstNumber("targetLeanKg", "targetLeanMassKg") ?? derivedLean(weight: targetWeight, fat: targetFat)

        return initialFat != nil
            && initialLean != nil
            && currentFat != nil
            && currentLean != nil
            && targetFat != nil
            && targetLean != nil
    }

    func firstNumber(_ keys: String...) -> Double? {
        for key in keys {
            if let number = nestedNumber(key) {
                return number
            }
        }

        return nil
    }

    func compositionNumber(_ phase: String, _ key: String) -> Double? {
        nestedNumber(phase, key)
    }

    func derivedLean(weight: Double?, fat: Double?) -> Double? {
        guard let weight, let fat else { return nil }
        return max(0, weight - fat)
    }
}

struct PerformanceTab: View {
    let payload: InsightReportPayload?

    private var targetComparisonSection: InsightReportMetricSection? {
        [
            "target_vs_current_weight",
            "recomp_vector_plot",
            "initial_current_target_composition",
            "lean_vs_fat_mass",
            "lean_vs_fat_mass_target",
            "current_vs_target_weight"
        ]
            .compactMap { payload?.performance[$0] }
            .first { $0.hasWeightComparisonData || $0.hasLeanFatVectorData }
    }

    var body: some View {
        VStack(spacing: FormaSpacing.cardGap) {
            if payload?.performance.isEmpty != false {
                MetricsUnavailableContent(message: "Performance report data is unavailable.")
            }
            if let section = payload?.performance["ffmi_gauge"], section.numberValue != nil {
                FFMIGaugeCard(section: section)
            }
            if let section = payload?.performance["fmi_vs_ffmi"],
               (section.nestedNumber("ffmi") ?? section.nestedNumber("ffmiVal")) != nil,
               (section.nestedNumber("fmi") ?? section.nestedNumber("fmiVal")) != nil {
                CompositionMapCard(section: section)
            }
            if let section = payload?.performance["body_composition_flow"],
               (section.nestedNumber("leanMassKg") ?? section.nestedNumber("leanMass")) != nil,
               (section.nestedNumber("fatMassKg") ?? section.nestedNumber("fatMass")) != nil {
                BodyCompositionFlowCard(section: section)
            }
            if let section = payload?.performance["composition_trends"], !section.trends.isEmpty {
                CompositionTrendsCard(section: section)
            }
            if let section = targetComparisonSection {
                RecompVectorPlotCard(section: section)
            }
            if let section = payload?.performance["excess_fat_gauge"],
               section.nestedNumber("totalFatKg") != nil,
               section.nestedNumber("targetFatKg") != nil {
                ExcessFatGaugeCard(section: section)
            }
        }
        .padding(.horizontal, FormaSpacing.screenGutter)
        .padding(.top, FormaSpacing.xxs)
        .padding(.bottom, FormaSpacing.xl)
    }
}

// MARK: - FFMI Gauge Card

struct FFMIGaugeCard: View {
    let section: InsightReportMetricSection?
    private var value: Double { min(25, max(15, section?.numberValue ?? 19.5)) }

    private var statusColor: Color {
        Self.gaugeSegments.first(where: { value < $0.max })?.color ?? Color.performancePositive
    }

    private static let gaugeSegments: [FormaGaugeSegment] = [
        FormaGaugeSegment(color: .performanceNegative, min: 15, max: 17),
        FormaGaugeSegment(color: .performanceCaution, min: 17, max: 19),
        FormaGaugeSegment(color: .performancePrimary, min: 19, max: 21),
        FormaGaugeSegment(color: .performanceSecondary, min: 21, max: 23),
        FormaGaugeSegment(color: .performancePositive, min: 23, max: 25)
    ]

    private static let categories: [FormaLegendCategory] = [
        FormaLegendCategory(name: "Low", range: "< 17", color: .performanceNegative, min: 0, max: 17),
        FormaLegendCategory(name: "Average", range: "17-19", color: .performanceCaution, min: 17, max: 19),
        FormaLegendCategory(name: "Fit", range: "19-21", color: .performancePrimary, min: 19, max: 21),
        FormaLegendCategory(name: "Athletic", range: "21-23", color: .performanceSecondary, min: 21, max: 23),
        FormaLegendCategory(name: "Elite", range: "> 23", color: .performancePositive, min: 23, max: 100)
    ]

    private var calloutText: String {
        section?.remark?.text ?? section?.displayComment ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader(
                section?.displayTitle ?? "FFMI Gauge",
                subtitle: section?.title ?? "Fat-Free Mass Index measures your muscle mass relative to height."
            )

            FormaSemicircularGauge(
                value: value,
                accent: statusColor,
                segments: Self.gaugeSegments,
                range: 15...25,
                tickLabels: [15, 17, 19, 21, 23, 25],
                valueText: String(format: "%.1f", value),
                caption: "YOUR FFMI"
            )
            .padding(.top, FormaSpacing.xs)

            FormaCategoryLegend(categories: Self.categories, selectedValue: value)
                .padding(.top, FormaSpacing.xxs)

            if !calloutText.isEmpty {
                FormaDivider()

                FormaCallout(
                    text: calloutText,
                    systemImage: section?.remark?.marker?.iconName ?? "sparkles",
                    tint: section?.remark?.marker?.color ?? Color.performancePrimary
                )
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
    }
}

// MARK: - Composition Map Card

struct CompositionMapCard: View {
    let section: InsightReportMetricSection?

    private var ffmi: Double {
        section?.nestedNumber("ffmi") ?? section?.nestedNumber("ffmiVal") ?? 19.52
    }

    private var fmi: Double {
        section?.nestedNumber("fmi") ?? section?.nestedNumber("fmiVal") ?? 6.42
    }

    private var calloutText: String {
        section?.remark?.text ?? section?.displayComment ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader(
                section?.displayTitle ?? "Composition Map",
                subtitle: section?.title ?? "Compare your Fat-Free Mass Index (muscle) against your Fat Mass Index (fat)."
            )

            // Main chart area with labeled axes
            VStack(spacing: FormaSpacing.xs) {
                HStack(spacing: 12) {
                    Text("FMI — Fat Mass")
                        .font(FormaTypography.chartLabel)
                        .foregroundStyle(.secondary)
                        .fixedSize()
                        .rotationEffect(.degrees(-90))
                        .frame(width: 16)

                    CompositionQuadrantChart(ffmi: ffmi, fmi: fmi)
                }

                Text("FFMI — Fat-Free Mass")
                    .font(FormaTypography.chartLabel)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.leading, 28)
            }
            .padding(.vertical, FormaSpacing.xs)

            // Legend
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.performancePrimary.gradient)
                    .frame(width: 10, height: 10)

                Text("Your Position (\(String(format: "%.2f", ffmi)), \(String(format: "%.2f", fmi)))")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .center)

            if !calloutText.isEmpty {
                FormaDivider()

                FormaCallout(
                    text: calloutText,
                    systemImage: section?.remark?.marker?.iconName ?? "map.fill",
                    tint: section?.remark?.marker?.color ?? Color.performancePrimary
                )
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
    }
}

// MARK: - Composition Quadrant Chart

struct CompositionQuadrantChart: View {
    let ffmi: Double
    let fmi: Double

    let ffmiThreshold: Double = 19.5
    let fmiThreshold: Double = 6.0

    let minFFMI: Double = 16.0
    let maxFFMI: Double = 23.0
    let minFMI: Double = 3.0
    let maxFMI: Double = 9.0

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height

            let thresholdX = max(0, min(width, (ffmiThreshold - minFFMI) / (maxFFMI - minFFMI) * width))
            let thresholdY = max(0, min(height, height - ((fmiThreshold - minFMI) / (maxFMI - minFMI) * height)))

            ZStack {
                // Top-Left: Skinny Fat
                Rectangle()
                    .fill(Color.performanceCaution.opacity(0.08))
                    .frame(width: thresholdX, height: thresholdY)
                    .position(x: thresholdX / 2, y: thresholdY / 2)

                // Top-Right: Big & Muscular
                Rectangle()
                    .fill(Color.performanceSecondary.opacity(0.08))
                    .frame(width: width - thresholdX, height: thresholdY)
                    .position(x: thresholdX + (width - thresholdX) / 2, y: thresholdY / 2)

                // Bottom-Left: Lean
                Rectangle()
                    .fill(Color.performancePositive.opacity(0.08))
                    .frame(width: thresholdX, height: height - thresholdY)
                    .position(x: thresholdX / 2, y: thresholdY + (height - thresholdY) / 2)

                // Bottom-Right: Athletic
                Rectangle()
                    .fill(Color.performancePrimary.opacity(0.08))
                    .frame(width: width - thresholdX, height: height - thresholdY)
                    .position(x: thresholdX + (width - thresholdX) / 2, y: thresholdY + (height - thresholdY) / 2)

                // Labels
                Text("Skinny Fat")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.performanceCaution.opacity(0.8))
                    .position(x: thresholdX / 2, y: thresholdY / 2)

                Text("Big & Muscular")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.performanceSecondary.opacity(0.8))
                    .position(x: thresholdX + (width - thresholdX) / 2, y: thresholdY / 2)

                Text("Lean")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.performancePositive.opacity(0.8))
                    .position(x: thresholdX / 2, y: thresholdY + (height - thresholdY) / 2)

                Text("Athletic")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.performancePrimary.opacity(0.8))
                    .position(x: thresholdX + (width - thresholdX) / 2, y: thresholdY + (height - thresholdY) / 2)

                // Axes Lines
                Path { path in
                    path.move(to: CGPoint(x: thresholdX, y: 0))
                    path.addLine(to: CGPoint(x: thresholdX, y: height))
                    path.move(to: CGPoint(x: 0, y: thresholdY))
                    path.addLine(to: CGPoint(x: width, y: thresholdY))
                }
                .stroke(Color.primary.opacity(0.2), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))

                // User Marker
                let userX = max(0, min(width, (ffmi - minFFMI) / (maxFFMI - minFFMI) * width))
                let userY = max(0, min(height, height - ((fmi - minFMI) / (maxFMI - minFMI) * height)))

                Circle()
                    .stroke(Color.performancePrimary.opacity(0.35), lineWidth: 8)
                    .frame(width: 26, height: 26)
                    .position(x: userX, y: userY)

                Circle()
                    .fill(Color.performancePrimary.gradient)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle().stroke(Color.appMarkerRing, lineWidth: 2)
                    )
                    .shadow(color: Color.performancePrimary.opacity(0.4), radius: 4, x: 0, y: 2)
                    .position(x: userX, y: userY)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Body composition quadrant")
        .accessibilityValue("Your position is FFMI \(String(format: "%.1f", ffmi)), FMI \(String(format: "%.1f", fmi))")
    }
}

// MARK: - Body Composition Flow Card

struct BodyCompositionFlowCard: View {
    let section: InsightReportMetricSection?

    private var leanMass: Double {
        section?.nestedNumber("leanMassKg") ?? section?.nestedNumber("leanMass") ?? 0
    }

    private var fatMass: Double {
        section?.nestedNumber("fatMassKg") ?? section?.nestedNumber("fatMass") ?? 0
    }

    /// Latest reports only ship lean + fat; older payloads may include total weight.
    private var totalWeight: Double {
        if let explicit = section?.nestedNumber("totalWeightKg") ?? section?.nestedNumber("totalWeight") {
            return explicit
        }
        return leanMass + fatMass
    }

    private var leanPct: Double {
        totalWeight > 0 ? (leanMass / totalWeight) * 100 : 0
    }

    private var fatPct: Double {
        totalWeight > 0 ? (fatMass / totalWeight) * 100 : 0
    }

    private var calloutText: String {
        section?.remark?.text ?? section?.displayComment ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader(
                section?.displayTitle ?? "Body Composition Flow",
                subtitle: section?.title ?? "Breaks down your total body weight into lean mass and fat mass."
            )

            // Flow Diagram
            HStack(spacing: 0) {
                // Source Node
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Weight")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.performancePrimary)
                    Text(String(format: "%.2f kg", totalWeight))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 14)
                .frame(width: 115, height: 76, alignment: .leading)
                .background(Color.performancePrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous)
                        .stroke(Color.performancePrimary.opacity(0.2), lineWidth: 0.5)
                )
                .zIndex(1)

                // Flow Connections
                GeometryReader { geo in
                    let h = geo.size.height

                    let boxHeight: CGFloat = 76
                    let spacing: CGFloat = 12

                    // Left Node is vertically centered in the HStack
                    let centerY = h / 2
                    let leftTopY = centerY - (boxHeight / 2)
                    let leftBottomY = centerY + (boxHeight / 2)
                    let leanRatio = totalWeight > 0 ? CGFloat(leanMass / totalWeight) : 0.75
                    let leftSplitY = leftTopY + (boxHeight * leanRatio)

                    // Right nodes are stacked with 12pt spacing and exactly span 0...164
                    let rightLeanTopY: CGFloat = 0
                    let rightLeanBottomY = boxHeight

                    let rightFatTopY = boxHeight + spacing
                    let rightFatBottomY = rightFatTopY + boxHeight

                    ZStack {
                        // Lean Flow Ribbon
                        SankeyRibbon(
                            startY1: leftTopY,
                            startY2: leftSplitY,
                            endY1: rightLeanTopY,
                            endY2: rightLeanBottomY
                        )
                        .fill(
                            LinearGradient(
                                colors: [Color.performancePrimary.opacity(0.4), Color.performancePositive.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                        // Fat Flow Ribbon
                        SankeyRibbon(
                            startY1: leftSplitY + 1.5, // Tiny gap for visual separation
                            startY2: leftBottomY,
                            endY1: rightFatTopY,
                            endY2: rightFatBottomY
                        )
                        .fill(
                            LinearGradient(
                                colors: [Color.performancePrimary.opacity(0.4), Color.performanceNegative.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    }
                }
                .frame(width: 60)

                // Destination Nodes
                VStack(spacing: 12) {
                    // Lean Mass
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Lean Mass")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.performancePositive)

                        HStack(spacing: 4) {
                            Text(String(format: "%.2f kg", leanMass))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text(String(format: "%.1f%%", leanPct))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 76)
                    .background(Color.performancePositive.opacity(0.12), in: RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous)
                            .stroke(Color.performancePositive.opacity(0.2), lineWidth: 0.5)
                    )

                    // Fat Mass
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fat Mass")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.performanceNegative)

                        HStack(spacing: 4) {
                            Text(String(format: "%.2f kg", fatMass))
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text(String(format: "%.1f%%", fatPct))
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 76)
                    .background(Color.performanceNegative.opacity(0.12), in: RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous)
                            .stroke(Color.performanceNegative.opacity(0.2), lineWidth: 0.5)
                    )
                }
                .frame(height: 164)
                .zIndex(1)
            }
            .frame(height: 164)
            .padding(.top, FormaSpacing.xs)

            if !calloutText.isEmpty {
                FormaDivider()

                FormaCallout(
                    text: calloutText,
                    systemImage: section?.remark?.marker?.iconName ?? "arrow.triangle.branch",
                    tint: section?.remark?.marker?.color ?? Color.performancePrimary
                )
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
    }
}

// MARK: - Sankey Ribbon Shape

struct SankeyRibbon: Shape {
    var startY1: CGFloat
    var startY2: CGFloat
    var endY1: CGFloat
    var endY2: CGFloat
    var overlap: CGFloat = 8

    func path(in rect: CGRect) -> Path {
        var p = Path()

        let startX = -overlap
        let endX = rect.width + overlap
        let c1x = rect.width * 0.5

        p.move(to: CGPoint(x: startX, y: startY1))
        p.addCurve(
            to: CGPoint(x: endX, y: endY1),
            control1: CGPoint(x: c1x, y: startY1),
            control2: CGPoint(x: c1x, y: endY1)
        )
        p.addLine(to: CGPoint(x: endX, y: endY2))
        p.addCurve(
            to: CGPoint(x: startX, y: startY2),
            control1: CGPoint(x: c1x, y: endY2),
            control2: CGPoint(x: c1x, y: startY2)
        )
        p.closeSubpath()
        return p
    }
}

// MARK: - Composition Trends Card

struct CompositionTrend: Identifiable {
    let date: Date
    let value: Double
    let metric: String

    var id: String {
        "\(metric)|\(date.timeIntervalSinceReferenceDate)"
    }
}

struct CompositionTrendsCard: View {
    let section: InsightReportMetricSection?

    private var trendData: [CompositionTrend] {
        let reportData = (section?.trends ?? [:]).flatMap { key, points in
            points.map { CompositionTrend(date: $0.date, value: $0.value, metric: key.displayTrendLabel) }
        }

        return reportData.sorted {
            $0.date == $1.date ? $0.metric < $1.metric : $0.date < $1.date
        }
    }

    private var calloutText: String {
        section?.remark?.text ?? section?.displayComment ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader(
                section?.displayTitle ?? "Composition Trends",
                subtitle: section?.title ?? "Track changes in your lean mass and fat mass from your baseline."
            )

            FormaTimeSeriesChart(
                points: trendData.map {
                    FormaChartPoint(
                        date: $0.date,
                        value: $0.value,
                        metric: $0.metric,
                        color: colorForMetric($0.metric)
                    )
                },
                unit: "kg",
                includeZero: true
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Composition trends chart")
            .accessibilityValue("Shows lean mass and fat mass changes over time")

            if !calloutText.isEmpty {
                FormaDivider()

                FormaCallout(
                    text: calloutText,
                    systemImage: section?.remark?.marker?.iconName ?? "chart.xyaxis.line",
                    tint: section?.remark?.marker?.color ?? Color.performancePrimary
                )
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
    }

    private func colorForMetric(_ metric: String) -> Color {
        switch metric {
        case "Lean Mass", "Muscle Mass", "Skeletal Muscle":
            return Color.performancePositive
        case "Fat Mass", "Body Fat":
            return Color.performanceNegative
        default:
            return Color.performancePrimary
        }
    }
}

// MARK: - Recomp Vector Plot Card

struct VectorPoint: Identifiable {
    let id = UUID()
    let fat: Double
    let lean: Double
    let phase: String
}

struct RecompVectorPlotCard: View {
    let section: InsightReportMetricSection?

    private var initialWeight: Double? {
        section?.firstNumber("initialWeightKg", "initialWeight", "startWeightKg", "startWeight")
            ?? composedWeight("initial")
    }

    private var currentWeight: Double? {
        section?.firstNumber("currentWeightKg", "currentWeight")
            ?? composedWeight("current")
    }

    private var targetWeight: Double? {
        section?.firstNumber("targetWeightKg", "targetWeight")
            ?? composedWeight("target")
    }

    private var initialFat: Double? {
        section?.compositionNumber("initial", "fatMassKg")
            ?? section?.firstNumber("initialFatKg", "initialFatMassKg", "startFatKg", "startFatMassKg")
    }

    private var initialLean: Double? {
        section?.compositionNumber("initial", "leanMassKg")
            ?? section?.firstNumber("initialLeanKg", "initialLeanMassKg", "startLeanKg", "startLeanMassKg")
            ?? section?.derivedLean(weight: initialWeight, fat: initialFat)
    }

    private var currentFat: Double? {
        section?.compositionNumber("current", "fatMassKg")
            ?? section?.firstNumber("currentFatKg", "currentFatMassKg", "totalFatKg")
    }

    private var currentLean: Double? {
        section?.compositionNumber("current", "leanMassKg")
            ?? section?.firstNumber("currentLeanKg", "currentLeanMassKg", "totalLeanKg")
            ?? section?.derivedLean(weight: currentWeight, fat: currentFat)
    }

    private var targetFat: Double? {
        section?.compositionNumber("target", "fatMassKg")
            ?? section?.firstNumber("targetFatKg", "targetFatMassKg")
    }

    private var targetLean: Double? {
        section?.compositionNumber("target", "leanMassKg")
            ?? section?.firstNumber("targetLeanKg", "targetLeanMassKg")
            ?? section?.derivedLean(weight: targetWeight, fat: targetFat)
    }

    private func composedWeight(_ phase: String) -> Double? {
        guard let lean = section?.compositionNumber(phase, "leanMassKg"),
              let fat = section?.compositionNumber(phase, "fatMassKg") else {
            return nil
        }

        return lean + fat
    }

    private var vectorValues: (initialFat: Double, initialLean: Double, currentFat: Double, currentLean: Double, targetFat: Double, targetLean: Double)? {
        guard let initialFat, let initialLean, let currentFat, let currentLean, let targetFat, let targetLean else {
            return nil
        }

        return (initialFat, initialLean, currentFat, currentLean, targetFat, targetLean)
    }

    private func xDomain(for values: (initialFat: Double, initialLean: Double, currentFat: Double, currentLean: Double, targetFat: Double, targetLean: Double)) -> ClosedRange<Double> {
        let startFat = values.initialFat
        let targetFat = values.targetFat
        let minFat = min(startFat, targetFat)
        let maxFat = max(startFat, targetFat)
        return (minFat - 2.0)...(maxFat + 2.0)
    }

    private func yDomain(for values: (initialFat: Double, initialLean: Double, currentFat: Double, currentLean: Double, targetFat: Double, targetLean: Double)) -> ClosedRange<Double> {
        let startLean = values.initialLean
        let currentLean = values.currentLean
        let minLean = min(startLean, currentLean)
        let maxLean = max(startLean, currentLean)
        return (minLean - 2.0)...(maxLean + 2.0)
    }

    private func vectorData(for values: (initialFat: Double, initialLean: Double, currentFat: Double, currentLean: Double, targetFat: Double, targetLean: Double)) -> [VectorPoint] {
        [
            VectorPoint(fat: values.initialFat, lean: values.initialLean, phase: "History"),
            VectorPoint(fat: values.currentFat, lean: values.currentLean, phase: "History"),
            VectorPoint(fat: values.currentFat, lean: values.currentLean, phase: "Future"),
            VectorPoint(fat: values.targetFat, lean: values.targetLean, phase: "Future")
        ]
    }

    private var calloutText: String {
        section?.remark?.text ?? section?.displayComment ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader(
                section?.displayTitle ?? "Recomp Vector Plot",
                subtitle: section?.title ?? "Track your body composition journey across distinct zones."
            )

            if let values = vectorValues {
                // Chart Area
                VStack(alignment: .leading, spacing: 14) {
                    Chart {
                        RecompLineMarks(vectorData: vectorData(for: values))
                        RecompArrowMark(fat: (values.currentFat + values.targetFat) / 2, lean: (values.currentLean + values.targetLean) / 2)
                        RecompStartMark(fat: values.initialFat, lean: values.initialLean)
                        RecompCurrentMark(fat: values.currentFat, lean: values.currentLean)
                        RecompTargetMark(fat: values.targetFat, lean: values.targetLean)
                    }
                    .chartForegroundStyleScale([
                        "History": Color.secondary.opacity(0.5),
                        "Future": Color.performancePositive
                    ])
                    .chartLineStyleScale([
                        "History": StrokeStyle(lineWidth: 1.75, lineCap: .round, lineJoin: .round),
                        "Future": StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round, dash: [4, 4])
                    ])
                    .chartLegend(.hidden)
                    .chartXScale(domain: xDomain(for: values))
                    .chartYScale(domain: yDomain(for: values))
                    .chartXAxisLabel("Fat Mass (kg)", position: .bottom, alignment: .center)
                    .chartYAxisLabel("Lean Mass (kg)", position: .leading, alignment: .center)
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 3)) { _ in
                            AxisTick(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.secondary.opacity(0.20))
                            AxisValueLabel()
                                .font(FormaTypography.chartLabel)
                                .foregroundStyle(Color.secondary.opacity(FormaChartStyle.axisLabelOpacity))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                            AxisGridLine(stroke: FormaChartStyle.gridLineStyle)
                                .foregroundStyle(Color.secondary.opacity(FormaChartStyle.gridOpacity))
                            AxisValueLabel()
                                .font(FormaTypography.chartLabel)
                                .foregroundStyle(Color.secondary.opacity(FormaChartStyle.axisLabelOpacity))
                        }
                    }
                    .frame(height: 220)
                    .padding(.top, 10)

                    // Encoding legend
                    HStack(spacing: FormaSpacing.lg) {
                        legendSwatch(color: Color.secondary.opacity(0.6), dashed: false, label: "History")
                        legendSwatch(color: Color.performancePositive, dashed: true, label: "Goal path")
                        Spacer()
                    }
                }
                .padding(FormaSpacing.md)
                .background(
                    RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous)
                        .fill(Color.appChartBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous)
                        .stroke(Color.appSeparator, lineWidth: 0.5)
                )
            }

            // Weight Summary
            if let currentWeight, let targetWeight {
                RecompWeightSummary(currentWeight: currentWeight, targetWeight: targetWeight)
            }

            if !calloutText.isEmpty {
                FormaDivider()

                FormaCallout(
                    text: calloutText,
                    systemImage: section?.remark?.marker?.iconName ?? "target",
                    tint: section?.remark?.marker?.color ?? Color.performancePositive
                )
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
    }

    private func legendSwatch(color: Color, dashed: Bool, label: String) -> some View {
        HStack(spacing: 6) {
            Path { path in
                path.move(to: .zero)
                path.addLine(to: CGPoint(x: 18, y: 0))
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: dashed ? [4, 3] : []))
            .frame(width: 18, height: 2)

            Text(label)
                .font(FormaTypography.micro)
                .foregroundStyle(.secondary)
        }
    }
}

private struct RecompWeightSummary: View {
    let currentWeight: Double
    let targetWeight: Double

    var body: some View {
        HStack {
            Spacer()

            weight(label: "Current Weight", value: String(format: "%.1f kg", currentWeight))
            Spacer()

            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.performancePositive)

            Spacer()
            weight(label: "Target Weight", value: String(format: "%.1f kg", targetWeight))
            Spacer()
        }
        .padding(.vertical, FormaSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous)
                .fill(Color.performancePositive.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: FormaRadius.inset, style: .continuous)
                .stroke(Color.performancePositive.opacity(0.2), lineWidth: 0.5)
        )
    }

    private func weight(label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .foregroundStyle(.primary)
        }
    }
}

private struct RecompLineMarks: ChartContent {
    let vectorData: [VectorPoint]

    var body: some ChartContent {
        ForEach(vectorData) { item in
            LineMark(
                x: .value("Fat Mass", item.fat),
                y: .value("Lean Mass", item.lean)
            )
            .foregroundStyle(by: .value("Phase", item.phase))
            .lineStyle(by: .value("Phase", item.phase))
            .interpolationMethod(.monotone)
        }
    }
}

private struct RecompArrowMark: ChartContent {
    let fat: Double
    let lean: Double

    var body: some ChartContent {
        PointMark(x: .value("Fat", fat), y: .value("Lean", lean))
            .foregroundStyle(.clear)
            .annotation(position: .overlay) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 16, weight: .heavy))
                    .foregroundStyle(Color.performancePositive)
                    .background(Circle().fill(Color.appTertiaryBackground).frame(width: 20, height: 20))
            }
    }
}

private struct RecompStartMark: ChartContent {
    let fat: Double
    let lean: Double

    var body: some ChartContent {
        PointMark(x: .value("Fat", fat), y: .value("Lean", lean))
            .foregroundStyle(Color.secondary.opacity(0.7))
            .symbolSize(80)
            .annotation(position: .bottom) {
                Text("Initial")
                    .font(FormaTypography.micro.weight(.semibold))
                    .foregroundStyle(Color.secondary.opacity(0.7))
            }
    }
}

private struct RecompCurrentMark: ChartContent {
    let fat: Double
    let lean: Double

    var body: some ChartContent {
        PointMark(x: .value("Fat", fat), y: .value("Lean", lean))
            .foregroundStyle(Color.performancePrimary)
            .symbolSize(140)
            .symbol {
                Circle()
                    .fill(Color.performancePrimary)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.appMarkerRing, lineWidth: 2))
                    .shadow(color: Color.performancePrimary.opacity(0.3), radius: 3)
            }
            .annotation(position: .topTrailing) {
                Text("Current")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.performancePrimary)
            }
    }
}

private struct RecompTargetMark: ChartContent {
    let fat: Double
    let lean: Double

    var body: some ChartContent {
        PointMark(x: .value("Fat", fat), y: .value("Lean", lean))
            .foregroundStyle(Color.performancePositive)
            .symbolSize(140)
            .symbol {
                Circle()
                    .fill(Color.performancePositive)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(Color.appMarkerRing, lineWidth: 2))
                    .shadow(color: Color.performancePositive.opacity(0.3), radius: 3)
            }
            .annotation(position: .topLeading) {
                Text("Goal")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color.performancePositive)
            }
    }
}

// MARK: - Excess Fat Gauge Card

struct ExcessFatGaugeCard: View {
    let section: InsightReportMetricSection?
    var currentFat: Double { max(0.1, section?.nestedNumber("totalFatKg") ?? 0.1) }
    var targetFat: Double { min(currentFat, max(0, section?.nestedNumber("targetFatKg") ?? 0)) }

    var excessFat: Double {
        section?.nestedNumber("excessFatKg") ?? (currentFat - targetFat)
    }

    private var calloutText: String {
        section?.remark?.text ?? section?.displayComment ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader(
                section?.displayTitle ?? "Excess Fat Gauge",
                subtitle: section?.title ?? "Compare your current fat mass against your target fat mass."
            )

            // Gauge Visualization
            VStack(spacing: FormaSpacing.lg) {
                ExcessFatSemicircularGauge(current: currentFat, target: targetFat)
                    .padding(.top, FormaSpacing.xs)

                // Legend
                HStack(spacing: FormaSpacing.xl) {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color.performancePositive)
                            .frame(width: 14, height: 4)
                        Text("Target — \(String(format: "%.1f", targetFat)) kg")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color.performanceCaution)
                            .frame(width: 14, height: 4)
                        Text("Excess — \(String(format: "%.1f", excessFat)) kg")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                }
            }

            if !calloutText.isEmpty {
                FormaDivider()

                FormaCallout(
                    text: calloutText,
                    systemImage: section?.remark?.marker?.iconName ?? "flame",
                    tint: section?.remark?.marker?.color ?? Color.performanceCaution
                )
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
    }
}


struct ExcessFatSemicircularGauge: View {
    let current: Double
    let target: Double

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let strokeWidth = FormaSemicircularGaugeLayout.strokeWidth

            let safeCurrent = max(0.1, current)
            let safeTarget = min(safeCurrent, max(0, target))
            let targetFraction = safeTarget / safeCurrent
            let targetEndTrim = CGFloat(targetFraction) * 0.5
            let endTrim: CGFloat = 0.5

            ZStack {
                // Background Track
                Circle()
                    .trim(from: 0, to: 0.5)
                    .stroke(Color.appTertiaryBackground, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                    .rotationEffect(.degrees(180))
                    .frame(width: width, height: width)
                    .position(x: width / 2, y: height)

                // Target segment (Teal)
                Circle()
                    .trim(from: 0, to: targetEndTrim)
                    .stroke(Color.performancePositive.gradient, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                    .rotationEffect(.degrees(180))
                    .frame(width: width, height: width)
                    .position(x: width / 2, y: height)

                // Excess segment (Amber)
                Circle()
                    .trim(from: targetEndTrim, to: endTrim)
                    .stroke(Color.performanceCaution.gradient, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                    .rotationEffect(.degrees(180))
                    .frame(width: width, height: width)
                    .position(x: width / 2, y: height)

                // Separator between sections
                Circle()
                    .trim(from: targetEndTrim - 0.002, to: targetEndTrim + 0.002)
                    .stroke(Color.appSecondaryBackground, style: StrokeStyle(lineWidth: strokeWidth + 2, lineCap: .butt))
                    .rotationEffect(.degrees(180))
                    .frame(width: width, height: width)
                    .position(x: width / 2, y: height)

                // Main Metric in Center
                VStack(spacing: 2) {
                    Text("\(String(format: "%.1f", current - target)) kg")
                        .font(FormaTypography.gaugeValue)
                        .foregroundStyle(.primary)

                    Text("TO LOSE")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)
                }
                .position(x: width / 2, y: height - FormaSemicircularGaugeLayout.scoreOffset)
            }
        }
        .aspectRatio(FormaSemicircularGaugeLayout.aspectRatio, contentMode: .fit)
    }
}

#Preview {
    PerformanceTab(payload: nil)
        .padding(.vertical, 20)
        .background(Color.appBackground)
}
