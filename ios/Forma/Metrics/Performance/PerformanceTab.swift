import SwiftUI
import Charts

private extension Color {
    /// A restrained, system-native palette that adapts naturally to light and dark mode.
    static let performancePrimary = Color(uiColor: .systemIndigo)
    static let performanceSecondary = Color(uiColor: .systemBlue)
    static let performancePositive = Color(uiColor: .systemTeal)
    static let performanceCaution = Color(uiColor: .systemOrange)
    static let performanceNegative = Color(uiColor: .systemRed)
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
                   (section.nestedNumber("totalWeightKg") ?? section.nestedNumber("totalWeight")) != nil,
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

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            FormaCardHeader(
                section?.displayTitle ?? "FFMI Gauge",
                subtitle: section?.title ?? "Fat-Free Mass Index measures your muscle mass relative to height."
            )
            
            // Gauge Visualization & Score
            FFMISemicircularGauge(value: value)
                .padding(.top, 10)
                .padding(.horizontal, 10)
            
            // Category legend
            FFMICategoryLegend(selectedValue: value)
                .padding(.top, 4)
            
            // Subtle separator
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
            
            // Insight text
            FormaCallout(
                text: section?.displayComment ?? "FFMI around 20 reflects a well-trained frame with room to reveal more definition as fat comes down.",
                tint: Color.performancePrimary
            )
        }
        .formaMetricCard()
    }
}

// MARK: - FFMI Semicircular Gauge

struct FFMISemicircularGauge: View {
    let value: Double
    
    let segments: [(color: Color, min: Double, max: Double)] = [
        (Color.performanceNegative, 15, 17),
        (Color.performanceCaution, 17, 19),
        (Color.performancePrimary, 19, 21),
        (Color.performanceSecondary, 21, 23),
        (Color.performancePositive, 23, 25)
    ]
    
    let labels: [Double] = [15, 17, 19, 21, 23, 25]
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let radius = width / 2
            let strokeWidth: CGFloat = 20
            
            ZStack {
                // Colored Segments
                ZStack {
                    ForEach(0..<segments.count, id: \.self) { index in
                        let segment = segments[index]
                        let startTrim = CGFloat((segment.min - 15) / 10.0) * 0.5
                        let endTrim = CGFloat((segment.max - 15) / 10.0) * 0.5
                        
                        Circle()
                            .trim(from: startTrim, to: endTrim)
                            .stroke(segment.color.gradient, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                            .rotationEffect(.degrees(180))
                    }
                }
                .frame(width: width, height: width)
                .position(x: width / 2, y: height)
                
                // Range labels
                ForEach(labels, id: \.self) { labelValue in
                    let t = (labelValue - 15) / 10.0
                    let angle = Angle(degrees: 180 - t * 180)
                    let labelRadius = radius - 30
                    
                    Text(String(format: "%.0f", labelValue))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .position(
                            x: width / 2 + labelRadius * CGFloat(cos(angle.radians)),
                            y: height - labelRadius * CGFloat(sin(angle.radians))
                        )
                }
                
                // Marker
                let valueT = max(0, min(1, (value - 15) / 10.0))
                let markerAngle = Angle(degrees: 180 - valueT * 180)
                
                Circle()
                    .fill(Color.appSecondaryBackground)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle().stroke(Color.primary, lineWidth: 3.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    .position(
                        x: width / 2 + radius * CGFloat(cos(markerAngle.radians)),
                        y: height - radius * CGFloat(sin(markerAngle.radians))
                    )
                
                // Score
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("YOUR FFMI")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(0.6)
                }
                .position(x: width / 2, y: height - 20)
            }
        }
        .aspectRatio(2.0, contentMode: .fit)
    }
}

// MARK: - FFMI Category Legend

struct FFMICategoryLegend: View {
    let selectedValue: Double
    
    let categories: [(name: String, range: String, color: Color, min: Double, max: Double)] = [
        ("Low", "< 17", Color.performanceNegative, 0, 17),
        ("Average", "17-19", Color.performanceCaution, 17, 19),
        ("Fit", "19-21", Color.performancePrimary, 19, 21),
        ("Athletic", "21-23", Color.performanceSecondary, 21, 23),
        ("Elite", "> 23", Color.performancePositive, 23, 100)
    ]
    
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
                        .font(.system(size: 9, weight: .regular))
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}

#Preview {
    PerformanceTab(payload: nil)
        .padding(.vertical, 20)
        .background(Color.appBackground)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            FormaCardHeader(
                section?.displayTitle ?? "Composition Map",
                subtitle: section?.title ?? "Compare your Fat-Free Mass Index (muscle) against your Fat Mass Index (fat)."
            )
            
            // Main Chart Area
            HStack(spacing: 12) {
                // Y Axis Label
                Text("FMI — Fat Mass")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
                    .frame(width: 16)

                CompositionQuadrantChart(ffmi: ffmi, fmi: fmi)
            }
            .padding(.vertical, 8)
            
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
            
            // Subtle separator
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
            
            // Bottom Remark Row
            FormaCallout(
                text: section?.remark?.text ?? section?.displayComment ?? "Your lean mass is well-developed. Lowering fat mass will make your muscle definition more visible.",
                systemImage: section?.remark?.marker?.iconName ?? "map.fill",
                tint: section?.remark?.marker?.color ?? Color.performancePrimary
            )
            .padding(.horizontal, 4)
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
                        Circle().stroke(Color.white, lineWidth: 2)
                    )
                    .shadow(color: Color.performancePrimary.opacity(0.4), radius: 4, x: 0, y: 2)
                    .position(x: userX, y: userY)
            }
        }
        .frame(height: 220)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Body composition quadrant")
        .accessibilityValue("Your position is FFMI \(String(format: "%.1f", ffmi)), FMI \(String(format: "%.1f", fmi))")
    }
}

// MARK: - Body Composition Flow Card

struct BodyCompositionFlowCard: View {
    let section: InsightReportMetricSection?
    
    private var totalWeight: Double {
        section?.nestedNumber("totalWeightKg") ?? section?.nestedNumber("totalWeight") ?? 76.75
    }
    
    private var leanMass: Double {
        section?.nestedNumber("leanMassKg") ?? section?.nestedNumber("leanMass") ?? 57.75
    }
    
    private var fatMass: Double {
        section?.nestedNumber("fatMassKg") ?? section?.nestedNumber("fatMass") ?? 19.00
    }
    
    private var leanPct: Double {
        totalWeight > 0 ? (leanMass / totalWeight) * 100 : 75.2
    }
    
    private var fatPct: Double {
        totalWeight > 0 ? (fatMass / totalWeight) * 100 : 24.8
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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
                .background(Color.performancePrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.performancePrimary.opacity(0.2), lineWidth: 1)
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
                    
                    // Right Nodes are stacked with 12pt spacing
                    // Total height of right nodes = 76 + 12 + 76 = 164
                    // Since HStack height is 164, they exactly span from 0 to 164
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
                    .background(Color.performancePositive.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.performancePositive.opacity(0.2), lineWidth: 1)
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
                    .background(Color.performanceNegative.opacity(0.12), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.performanceNegative.opacity(0.2), lineWidth: 1)
                    )
                }
                .frame(height: 164)
                .zIndex(1)
            }
            .frame(height: 164)
            .padding(.top, 8)
            
            // Subtle separator
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
            
            // Bottom Remark Row
            FormaCallout(
                text: section?.remark?.text ?? section?.displayComment ?? "Lean mass is solid, fat mass is trending downward, and the ratio is improving over time.",
                systemImage: section?.remark?.marker?.iconName ?? "arrow.triangle.branch",
                tint: section?.remark?.marker?.color ?? Color.performancePrimary
            )
            .padding(.horizontal, 4)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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
            
            // Subtle separator
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
            
            // Insight text
            FormaCallout(
                text: section?.displayComment ?? "",
                systemImage: "chart.line.downtrend.xyaxis",
                tint: Color.performanceNegative
            )
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
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
                    "History": Color.gray.opacity(0.5),
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
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: FormaChartStyle.gridLineStyle)
                            .foregroundStyle(Color.secondary.opacity(FormaChartStyle.gridOpacity))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(Color.secondary.opacity(FormaChartStyle.axisLabelOpacity))
                    }
                }
                .frame(height: 220)
                .padding(.top, 10)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.appTertiaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.appSeparator, lineWidth: 0.5)
            )
            }
            
            // Weight Summary
            if let currentWeight, let targetWeight {
                RecompWeightSummary(currentWeight: currentWeight, targetWeight: targetWeight)
            }
            
            // Bottom Remark Row
            FormaCallout(
                text: section?.remark?.text ?? section?.displayComment ?? "There is a fat-loss target between your current and goal physique.",
                systemImage: section?.remark?.marker?.iconName ?? "target",
                tint: section?.remark?.marker?.color ?? Color.performancePositive
            )
            .padding(.horizontal, 4)
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
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
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.performancePositive.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.performancePositive.opacity(0.2), lineWidth: 1)
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
            .foregroundStyle(.gray)
            .symbolSize(80)
            .annotation(position: .bottom) {
                Text("Initial")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.gray)
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
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
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
                    .overlay(Circle().stroke(Color.white, lineWidth: 2))
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
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            FormaCardHeader(
                section?.displayTitle ?? "Excess Fat Gauge",
                subtitle: section?.title ?? "Compare your current fat mass against your target fat mass."
            )
            
            // Gauge Visualization
            VStack(spacing: 20) {
                ExcessFatSemicircularGauge(current: currentFat, target: targetFat)
                    .padding(.top, 10)
                    .padding(.horizontal, 10)
                
                // Legend
                HStack(spacing: 24) {
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
            
            // Subtle separator
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
            
            // Insight text
            FormaCallout(
                text: section?.displayComment ?? "The gap between current and target fat is clear and closeable. Every 0.5 kg drop moves you visibly closer.",
                systemImage: "flame",
                tint: Color.performanceCaution
            )
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
            let strokeWidth: CGFloat = 24
            
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
                
                // Target segment (Green)
                Circle()
                    .trim(from: 0, to: targetEndTrim)
                    .stroke(Color.performancePositive.gradient, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt))
                    .rotationEffect(.degrees(180))
                    .frame(width: width, height: width)
                    .position(x: width / 2, y: height)
                
                // Excess segment (Orange)
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
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text("TO LOSE")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                }
                .position(x: width / 2, y: height - 20)
            }
        }
        .aspectRatio(2.0, contentMode: .fit)
    }
}

// MARK: - Body Measurements Card

private enum MeasurementSide {
    case left
    case right
}

private struct BodyMeasurement: Identifiable {
    let id = UUID()
    let name: String
    let value: Double
    let side: MeasurementSide
    let labelY: CGFloat
    let markerOffset: CGPoint
}

struct BodyMeasurementsCard: View {
    private let measurements: [BodyMeasurement] = [
        BodyMeasurement(name: "Neck", value: 37, side: .left, labelY: 82, markerOffset: CGPoint(x: 0, y: 118)),
        BodyMeasurement(name: "Chest", value: 106, side: .left, labelY: 138, markerOffset: CGPoint(x: -11, y: 139)),
        BodyMeasurement(name: "Waist", value: 90, side: .left, labelY: 194, markerOffset: CGPoint(x: -10, y: 163)),
        BodyMeasurement(name: "Calf", value: 37, side: .left, labelY: 262, markerOffset: CGPoint(x: -11, y: 219)),
        BodyMeasurement(name: "Shoulder", value: 103, side: .right, labelY: 82, markerOffset: CGPoint(x: 14, y: 126)),
        BodyMeasurement(name: "Bicep", value: 35, side: .right, labelY: 138, markerOffset: CGPoint(x: 22, y: 145)),
        BodyMeasurement(name: "Stomach", value: 97, side: .right, labelY: 194, markerOffset: CGPoint(x: 5, y: 172)),
        BodyMeasurement(name: "Thigh", value: 52, side: .right, labelY: 250, markerOffset: CGPoint(x: 8, y: 198))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            BodyMeasurementsHeader()
            BodyMeasurementsMap(measurements: measurements)
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
    }
}

private struct BodyMeasurementsHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Body Measurements")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("A spatial overview of circumference and body proportions.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct BodyMeasurementsMap: View {
    let measurements: [BodyMeasurement]

    var body: some View {
        GeometryReader { geometry in
            let centerX = geometry.size.width / 2
            let imageCenterY: CGFloat = 174 // Center Y of the map area
            let imageWidth: CGFloat = 160
            let imageHeight: CGFloat = 240
            
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appTertiaryBackground)

                // Subtle radial glow behind the body
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.performancePrimary.opacity(0.08),
                                Color.performancePrimary.opacity(0.02),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 10,
                            endRadius: 110
                        )
                    )
                    .frame(width: 180, height: 260)
                    .position(x: centerX, y: imageCenterY)

                Image("body")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: imageWidth, height: imageHeight)
                    .position(x: centerX, y: imageCenterY)

                ForEach(measurements) { measurement in
                    BodyMeasurementConnector(
                        measurement: measurement,
                        containerWidth: geometry.size.width,
                        containerHeight: geometry.size.height,
                        centerX: centerX
                    )

                    BodyMeasurementLabel(measurement: measurement)
                        .position(
                            x: measurement.side == .left ? 50 : geometry.size.width - 50,
                            y: measurement.labelY
                        )
                }
            }
        }
        .frame(height: 320)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 0.5)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Body circumference measurements")
    }
}

private struct BodyMeasurementConnector: View {
    let measurement: BodyMeasurement
    let containerWidth: CGFloat
    let containerHeight: CGFloat
    let centerX: CGFloat

    var body: some View {
        let marker = CGPoint(
            x: centerX + measurement.markerOffset.x,
            y: measurement.markerOffset.y
        )
        // Labels have a fixed width (88), so we connect to their edge
        let labelEdgeX: CGFloat = measurement.side == .left ? 94 : containerWidth - 94
        
        // Ensure the elbow always moves inward towards the body before breaking to the marker
        let elbowX: CGFloat = measurement.side == .left 
            ? min(marker.x - 20, labelEdgeX + 20) 
            : max(marker.x + 20, labelEdgeX - 20)

        ZStack {
            Path { path in
                path.move(to: CGPoint(x: labelEdgeX, y: measurement.labelY))
                path.addLine(to: CGPoint(x: elbowX, y: measurement.labelY))
                path.addLine(to: marker)
            }
            .stroke(
                Color.performancePrimary.opacity(0.35),
                style: StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round, dash: [4, 3])
            )

            Circle()
                .fill(Color.appSecondaryBackground)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(Color.performancePrimary.opacity(0.8), lineWidth: 2))
                .shadow(color: Color.performancePrimary.opacity(0.2), radius: 3, x: 0, y: 0)
                .position(marker)
        }
        .frame(width: containerWidth, height: containerHeight)
    }
}

private struct BodyMeasurementLabel: View {
    let measurement: BodyMeasurement

    var body: some View {
        VStack(
            alignment: measurement.side == .left ? .leading : .trailing,
            spacing: 3
        ) {
            Text(measurement.name.uppercased())
                .font(.system(size: 9, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(.secondary)

            Text(measurement.value, format: .number.precision(.fractionLength(1)))
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.performancePrimary.opacity(0.10))
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.performancePrimary.opacity(0.15), lineWidth: 0.5)
                )

            Text("cm")
                .font(.system(size: 8, weight: .medium))
                .foregroundStyle(.tertiary)
        }
        .frame(width: 88, alignment: measurement.side == .left ? .leading : .trailing)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(measurement.name), \(measurement.value, specifier: "%.1f") centimeters")
    }
}
