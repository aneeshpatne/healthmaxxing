import SwiftUI
import Charts

private extension Color {
    // Red for extremities (Low & High)
    static let extremityRed = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.40, blue: 0.40, alpha: 1.0)
            : UIColor(red: 0.88, green: 0.20, blue: 0.20, alpha: 1.0)
    })
    
    // Green for good (Optimal)
    static let goodGreen = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.35, green: 0.85, blue: 0.50, alpha: 1.0)
            : UIColor(red: 0.15, green: 0.65, blue: 0.30, alpha: 1.0)
    })
    
    // Yellow for warning & average
    static let avgYellow = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 1.0, green: 0.85, blue: 0.30, alpha: 1.0)
            : UIColor(red: 0.95, green: 0.70, blue: 0.10, alpha: 1.0)
    })
    
    // Main value text inside gauge
    static let valueDarkTeal = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.80, green: 0.95, blue: 0.95, alpha: 1.0)
            : UIColor(red: 0.05, green: 0.30, blue: 0.30, alpha: 1.0)
    })
    
    // Visceral vs Subcutaneous colors
    static let visceralDarkTeal = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.65, blue: 0.65, alpha: 1.0)
            : UIColor(red: 0.05, green: 0.40, blue: 0.40, alpha: 1.0)
    })
    
    static let subcutaneousLightTeal = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.45, green: 0.85, blue: 0.85, alpha: 1.0)
            : UIColor(red: 0.20, green: 0.70, blue: 0.70, alpha: 1.0)
    })
    
    static let innerPanelBackground = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.12, green: 0.14, blue: 0.16, alpha: 1.0)
            : UIColor(red: 0.94, green: 0.96, blue: 0.98, alpha: 1.0)
    })
}

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
    
    var remarkText: String {
        if value < 6.0 {
            return "Below optimal essential range. Ensure healthy fat intake."
        } else if value < 18.0 {
            return "Within optimal athletic range. Great job keeping it steady!"
        } else if value < 25.0 {
            return "Above your target of 18%. Aim for steady fat reduction."
        } else {
            return "Significantly above target. Prioritize active fat reduction."
        }
    }
    
    var statusColor: Color {
        if value < 6.0 {
            return Color.extremityRed
        } else if value < 18.0 {
            return Color.goodGreen
        } else if value < 25.0 {
            return Color.avgYellow
        } else {
            return Color.extremityRed
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
        VStack(spacing: 20) {
            if payload?.fat.isEmpty != false {
                MetricsUnavailableContent(message: "Fat report data is unavailable.")
            }

            if let section = payload?.fat["fat_ratio"], let value = section.numberValue {
            FatRatioCard(
                value: value,
                comment: section.comment,
                remark: section.remark
            )
            }
            
            if let section = payload?.fat["visceral_vs_subcutaneous"],
               let visceralFat = section.nestedNumber("visceralFatDeltaKg"),
               let subcutaneousFat = section.nestedNumber("subcutaneousFatDeltaKg") {
            VisceralSubcutaneousCard(
                visceralFat: visceralFat,
                subcutaneousFat: subcutaneousFat,
                verdict: section.title ?? section.displayTitle,
                remark: section.remark,
                comment: section.comment
            )
            }
            
            if let section = payload?.fat["fat_ratio_trend"],
               let currentRatio = section.nestedNumber("visceral_vs_subcutaneous") {
            VisceralSubcRatioTrendCard(
                currentRatio: currentRatio,
                statusText: section.title ?? section.displayTitle,
                statusColor: .goodGreen,
                statusIcon: "checkmark.circle.fill",
                remark: section.remark,
                comment: section.comment,
                data: section.trendPoints(preferredKeys: ["visceral_vs_subcutaneous", "visceralSubcutaneousRatio", "ratio"])
                    .map { VisceralSubcRatioPoint(date: $0.date, value: $0.value) }
            )
            }
            
            if let section = payload?.fat["visceral_trend"], let currentMass = section.numberValue {
            VisceralFatMassTrendCard(
                currentMass: currentMass,
                statusText: section.title ?? section.displayTitle,
                statusColor: .goodGreen,
                statusIcon: "checkmark.circle.fill",
                remark: section.remark,
                comment: section.comment,
                data: section.trendPoints(preferredKeys: ["visceralFatKg", "visceral_fat_kg", "visceralFatMassKg"])
                    .map { VisceralFatMassPoint(date: $0.date, value: $0.value) }
            )
            }
            
            if let section = payload?.fat["subcutaneous_fat_mass_trend"], let currentMass = section.numberValue {
            SubcFatMassTrendCard(
                currentMass: currentMass,
                statusText: section.title ?? section.displayTitle,
                statusColor: .extremityRed,
                statusIcon: "exclamationmark.triangle.fill",
                remark: section.remark,
                comment: section.comment,
                data: section.trendPoints(preferredKeys: ["subcutaneousFatKg", "subcutaneous_fat_kg", "subcutaneousFatMassKg"])
                    .map { SubcFatMassPoint(date: $0.date, value: $0.value) }
            )
            }
            
            if let section = payload?.fat["fat_mass_trend"], let currentMass = section.numberValue {
            FatMassTrendCard(
                currentMass: currentMass,
                statusText: section.title ?? section.displayTitle,
                remark: section.remark,
                comment: section.comment,
                data: section.trendPoints(preferredKeys: ["fatMassKg", "fat_mass_kg", "totalFatKg"])
                    .map { FatMassPoint(date: $0.date, value: $0.value) }
            )
            }
            
            if let section = payload?.fat["fat_ratio"], let value = section.numberValue {
            FatHistoryCard(
                value: value,
                comment: section.comment,
                remark: section.remark,
                data: section.trendPoints(preferredKeys: ["body_fat_pct", "bodyFatPct", "fatRatio", "fat_ratio"])
                    .map { FatDataPoint(date: $0.date, ratio: $0.value) }
            )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
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
}

// MARK: - Fat Ratio Card

struct FatRatioZone {
    let name: String
    let min: Double
    let max: Double
    let rangeText: String
    let color: Color
}

struct FatRatioCard: View {
    var value: Double = 24.8
    var comment: String? = nil
    var remark: InsightReportRemark? = nil
    
    var metrics: FatRatioMetrics {
        FatRatioMetrics(value: value)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Body Fat Ratio")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(comment ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Gauge Semicircle Visualization
            FatSemicircularGauge(
                value: value,
                statusColor: metrics.statusColor,
                statusText: metrics.statusText,
                valueText: metrics.valueText
            )
            .padding(.top, 10)
            .padding(.horizontal, 10)
            
            // Category legend
            FatRatioCategoryLegend(selectedValue: value)
                .padding(.top, 4)
            
            // Horizontal Divider
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
            
            // Bottom Remark Row
            HStack(alignment: .top, spacing: 14) {
                let marker = remark?.marker
                Image(systemName: marker?.iconName ?? metrics.statusIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(marker?.color ?? metrics.statusColor)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill((marker?.color ?? metrics.statusColor).opacity(0.12))
                    )
                
                Text(remark?.text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appSecondaryBackground)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fat Ratio, \(String(format: "%.1f", value)) percent, \(metrics.statusText.lowercased()), \(metrics.verdictText.lowercased()).")
    }
}

// MARK: - Fat Semicircular Gauge

struct FatSemicircularGauge: View {
    let value: Double
    let statusColor: Color
    let statusText: String
    let valueText: String
    
    let segments: [(color: Color, min: Double, max: Double)] = [
        (Color.extremityRed, 2.0, 6.0),
        (Color.goodGreen, 6.0, 18.0),
        (Color.avgYellow, 18.0, 25.0),
        (Color.extremityRed, 25.0, 30.0)
    ]
    
    let labels: [Double] = [2, 6, 18, 25, 30]
    
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
                        let startTrim = CGFloat((segment.min - 2.0) / 28.0) * 0.5
                        let endTrim = CGFloat((segment.max - 2.0) / 28.0) * 0.5
                        
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
                    let t = (labelValue - 2.0) / 28.0
                    let angle = Angle(degrees: 180 - t * 180)
                    let labelRadius = radius - 30
                    
                    Text(String(format: "%.0f%%", labelValue))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .position(
                            x: width / 2 + labelRadius * CGFloat(cos(angle.radians)),
                            y: height - labelRadius * CGFloat(sin(angle.radians))
                        )
                }
                
                // Marker
                let valueT = max(0, min(1, (value - 2.0) / 28.0))
                let markerAngle = Angle(degrees: 180 - valueT * 180)
                
                Circle()
                    .fill(Color.appSecondaryBackground)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Circle().stroke(statusColor, lineWidth: 3.5)
                    )
                    .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
                    .position(
                        x: width / 2 + radius * CGFloat(cos(markerAngle.radians)),
                        y: height - radius * CGFloat(sin(markerAngle.radians))
                    )
                
                // Score
                VStack(spacing: 2) {
                    Text(valueText)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(statusText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(statusColor.opacity(0.12))
                        )
                }
                .position(x: width / 2, y: height - 25)
            }
        }
        .aspectRatio(2.0, contentMode: .fit)
    }
}

// MARK: - Fat Ratio Category Legend

struct FatRatioCategoryLegend: View {
    let selectedValue: Double
    
    let categories: [(name: String, range: String, color: Color, min: Double, max: Double)] = [
        ("Low", "< 6%", Color.extremityRed, 0, 6),
        ("Optimal", "6-18%", Color.goodGreen, 6, 18),
        ("Average", "18-25%", Color.avgYellow, 18, 25),
        ("High", "> 25%", Color.extremityRed, 25, 100)
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

// MARK: - Fat Ratio History

struct FatDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let ratio: Double
}

struct FatHistoryCard: View {
    var value: Double = 24.8
    var comment: String? = nil
    var remark: InsightReportRemark? = nil
    var reportData: [FatDataPoint]?
    
    var metrics: FatRatioMetrics {
        FatRatioMetrics(value: value)
    }
    
    init(value: Double = 24.8, comment: String? = nil, remark: InsightReportRemark? = nil, data: [FatDataPoint]? = nil) {
        self.value = value
        self.comment = comment
        self.remark = remark
        self.reportData = data
    }

    var data: [FatDataPoint] {
        reportData ?? []
    }

    private var yDomain: ClosedRange<Double> {
        let values = data.map { $0.ratio }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 24.0...26.5
        }
        if minVal == maxVal {
            return (minVal - 1)...(maxVal + 1)
        }
        let padding = (maxVal - minVal) * 0.15
        return (minVal - padding)...(maxVal + padding)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Fat Ratio History")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f%%", value))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                
                Text(comment ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Swift Chart
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Ratio", point.ratio)
                    )
                    .foregroundStyle(Color.goodGreen.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    
                    if point.id == data.last?.id {
                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Ratio", point.ratio)
                        )
                        .foregroundStyle(Color.goodGreen)
                        .symbol {
                            Circle()
                                .fill(Color.goodGreen)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                        }
                    }
                }
            }
            .chartYScale(domain: yDomain)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 180)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appTertiaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appSeparator, lineWidth: 0.5)
            )
            
            // Divider
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
                .padding(.horizontal, 4)
            
            // Bottom Remark Row
            HStack(alignment: .top, spacing: 14) {
                let marker = remark?.marker
                Image(systemName: marker?.iconName ?? metrics.statusIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(marker?.color ?? metrics.statusColor)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill((marker?.color ?? metrics.statusColor).opacity(0.12))
                    )
                
                Text(remark?.text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appSecondaryBackground)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fat Ratio, \(String(format: "%.1f", value)) percent, \(metrics.statusText.lowercased()), \(metrics.verdictText.lowercased()).")
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
            
            // Subcutaneous segment (Light Teal)
            Circle()
                .trim(from: subcutaneousTrimStart, to: 1.0 - gapOffset)
                .stroke(
                    Color.subcutaneousLightTeal.gradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            
            // Visceral segment (Dark Teal)
            Circle()
                .trim(from: gapOffset, to: visceralTrimEnd)
                .stroke(
                    Color.visceralDarkTeal.gradient,
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
    let visceralFat: Double
    let subcutaneousFat: Double
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
    
    var body: some View {
        VStack(spacing: 12) {
            // Header Row
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Visceral vs Subcutaneous")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        // Action or info trigger
                    }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("More information about visceral and subcutaneous fat.")
                }
                
                if let comment {
                    Text(comment)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            // Top Comparison Panel (Inner Panel)
            HStack(spacing: 16) {
                // Left Metric: Visceral Fat
                VStack(alignment: .center, spacing: 2) {
                    Text("Visceral Fat")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(String(format: "%.1f", visceralFat))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.visceralDarkTeal)
                        Text("kg")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(visceralPercentageText)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                
                // Center Donut Chart
                VisceralSubcutaneousDonutChart(visceralFraction: visceralFraction)
                
                // Right Metric: Subcutaneous Fat
                VStack(alignment: .center, spacing: 2) {
                    Text("Subcutaneous Fat")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                    
                    HStack(alignment: .firstTextBaseline, spacing: 1) {
                        Text(String(format: "%.1f", subcutaneousFat))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.subcutaneousLightTeal)
                        Text("kg")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(subcutaneousPercentageText)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.innerPanelBackground)
            )
            
            // Bottom Remark Row
            HStack(alignment: .top, spacing: 14) {
                let marker = remark?.marker
                Image(systemName: marker?.iconName ?? "info.circle")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(marker?.color ?? Color.subcutaneousLightTeal)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill((marker?.color ?? Color.subcutaneousLightTeal).opacity(0.12))
                    )
                
                Text(remark?.text ?? comment ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 2)
            .padding(.top, 4)
            .padding(.horizontal, 2)
            .padding(.top, 4)
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appSecondaryBackground)
                .shadow(color: Color.cardShadow, radius: 10, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Visceral fat \(String(format: "%.1f", visceralFat)) kilograms, \(visceralPercentageText). Subcutaneous fat \(String(format: "%.1f", subcutaneousFat)) kilograms, \(subcutaneousPercentageText). Verdict: \(verdict). Remark: \((remark?.text ?? "").replacingOccurrences(of: "\n", with: " ")).")
    }
}

// MARK: - Fat Mass Trend Card

struct FatMassPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct FatMassTrendCard: View {
    let currentMass: Double
    let statusText: String
    let remark: InsightReportRemark?
    let comment: String?
    var reportData: [FatMassPoint]?
    
    init(currentMass: Double, statusText: String, remark: InsightReportRemark? = nil, comment: String? = nil, data: [FatMassPoint]? = nil) {
        self.currentMass = currentMass
        self.statusText = statusText
        self.remark = remark
        self.comment = comment
        self.reportData = data
    }

    var data: [FatMassPoint] {
        reportData ?? []
    }

    private var yDomain: ClosedRange<Double> {
        let values = data.map { $0.value }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 15.0...21.5
        }
        if minVal == maxVal {
            return (minVal - 1)...(maxVal + 1)
        }
        let padding = (maxVal - minVal) * 0.15
        return (minVal - padding)...(maxVal + padding)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Header Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Fat Mass History")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f kg", currentMass))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                
                Text(comment ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Swift Chart
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Mass", point.value)
                    )
                    .foregroundStyle(Color.extremityRed.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    
                    if point.id == data.last?.id {
                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Mass", point.value)
                        )
                        .foregroundStyle(Color.extremityRed)
                        .symbol {
                            Circle()
                                .fill(Color.extremityRed)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                        }
                    }
                }
            }
            .chartYScale(domain: yDomain)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 180)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appTertiaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appSeparator, lineWidth: 0.5)
            )
            
            // Divider
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
                .padding(.horizontal, 4)
            
            // Bottom Remark Row
            HStack(alignment: .top, spacing: 14) {
                let marker = remark?.marker
                Image(systemName: marker?.iconName ?? "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(marker?.color ?? Color.extremityRed)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill((marker?.color ?? Color.extremityRed).opacity(0.12))
                    )
                
                Text(remark?.text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 4)
            .padding(.horizontal, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appSecondaryBackground)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Fat mass history over past 4 weeks, ending at \(String(format: "%.1f", currentMass)) kilograms. Current status is \(statusText). Remark: \((remark?.text ?? "").replacingOccurrences(of: "\n", with: " ")).")
    }
}

// MARK: - Visceral Subcutaneous Ratio Trend Card

struct VisceralSubcRatioPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct VisceralSubcRatioTrendCard: View {
    let currentRatio: Double
    let statusText: String
    let statusColor: Color
    let statusIcon: String
    let remark: InsightReportRemark?
    let comment: String?
    let data: [VisceralSubcRatioPoint]

    private var yDomain: ClosedRange<Double> {
        let values = data.map { $0.value }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 0.20...0.35
        }
        if minVal == maxVal {
            return (minVal - 0.05)...(maxVal + 0.05)
        }
        let padding = (maxVal - minVal) * 0.15
        return (minVal - padding)...(maxVal + padding)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Header Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Visceral / Subcutaneous Ratio")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(String(format: "%.2f", currentRatio))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                
                Text(comment ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Swift Chart
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Ratio", point.value)
                    )
                    .foregroundStyle(Color.visceralDarkTeal.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    
                    if point.id == data.last?.id {
                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Ratio", point.value)
                        )
                        .foregroundStyle(Color.visceralDarkTeal)
                        .symbol {
                            Circle()
                                .fill(Color.visceralDarkTeal)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                        }
                    }
                }
            }
            .chartYScale(domain: yDomain)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 180)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appTertiaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appSeparator, lineWidth: 0.5)
            )
            
            // Divider
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
                .padding(.horizontal, 4)
            
            // Bottom Remark Row
            HStack(alignment: .top, spacing: 14) {
                let marker = remark?.marker
                Image(systemName: marker?.iconName ?? statusIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(marker?.color ?? statusColor)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill((marker?.color ?? statusColor).opacity(0.12))
                    )
                
                Text(remark?.text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appSecondaryBackground)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Visceral to subcutaneous ratio history, ending at \(String(format: "%.2f", currentRatio)). Current status is \(statusText). Remark: \(remark?.text ?? "").")
    }
}

// MARK: - Subcutaneous Fat Mass Trend Card

struct SubcFatMassPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct SubcFatMassTrendCard: View {
    let currentMass: Double
    let statusText: String
    let statusColor: Color
    let statusIcon: String
    let remark: InsightReportRemark?
    let comment: String?
    let data: [SubcFatMassPoint]

    private var yDomain: ClosedRange<Double> {
        let values = data.map { $0.value }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 12.0...18.0
        }
        if minVal == maxVal {
            return (minVal - 1)...(maxVal + 1)
        }
        let padding = (maxVal - minVal) * 0.15
        return (minVal - padding)...(maxVal + padding)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Header Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Subcutaneous Fat Mass")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f kg", currentMass))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                
                Text(comment ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Swift Chart
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Mass", point.value)
                    )
                    .foregroundStyle(Color.subcutaneousLightTeal.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    
                    if point.id == data.last?.id {
                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Mass", point.value)
                        )
                        .foregroundStyle(Color.subcutaneousLightTeal)
                        .symbol {
                            Circle()
                                .fill(Color.subcutaneousLightTeal)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                        }
                    }
                }
            }
            .chartYScale(domain: yDomain)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 180)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appTertiaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appSeparator, lineWidth: 0.5)
            )
            
            // Divider
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
                .padding(.horizontal, 4)
            
            // Bottom Remark Row
            HStack(alignment: .top, spacing: 14) {
                let marker = remark?.marker
                Image(systemName: marker?.iconName ?? statusIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(marker?.color ?? statusColor)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill((marker?.color ?? statusColor).opacity(0.12))
                    )
                
                Text(remark?.text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appSecondaryBackground)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Subcutaneous fat mass history, ending at \(String(format: "%.1f", currentMass)) kilograms. Current status is \(statusText). Remark: \(remark?.text ?? "").")
    }
}

// MARK: - Visceral Fat Mass Trend Card

struct VisceralFatMassPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct VisceralFatMassTrendCard: View {
    let currentMass: Double
    let statusText: String
    let statusColor: Color
    let statusIcon: String
    let remark: InsightReportRemark?
    let comment: String?
    let data: [VisceralFatMassPoint]

    private var yDomain: ClosedRange<Double> {
        let values = data.map { $0.value }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 2.0...6.0
        }
        if minVal == maxVal {
            return (minVal - 1)...(maxVal + 1)
        }
        let padding = (maxVal - minVal) * 0.15
        return (minVal - padding)...(maxVal + padding)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top Header Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Visceral Fat Mass")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text(String(format: "%.1f kg", currentMass))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
                
                Text(comment ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Swift Chart
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Mass", point.value)
                    )
                    .foregroundStyle(Color.visceralDarkTeal.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    
                    if point.id == data.last?.id {
                        PointMark(
                            x: .value("Date", point.date, unit: .day),
                            y: .value("Mass", point.value)
                        )
                        .foregroundStyle(Color.visceralDarkTeal)
                        .symbol {
                            Circle()
                                .fill(Color.visceralDarkTeal)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                        }
                    }
                }
            }
            .chartYScale(domain: yDomain)
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 180)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appTertiaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appSeparator, lineWidth: 0.5)
            )
            
            // Divider
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
                .padding(.horizontal, 4)
            
            // Bottom Remark Row
            HStack(alignment: .top, spacing: 14) {
                let marker = remark?.marker
                Image(systemName: marker?.iconName ?? statusIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(marker?.color ?? statusColor)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill((marker?.color ?? statusColor).opacity(0.12))
                    )
                
                Text(remark?.text ?? "")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
            .padding(.horizontal, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.appSecondaryBackground)
                .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Visceral fat mass history, ending at \(String(format: "%.1f", currentMass)) kilograms. Current status is \(statusText). Remark: \(remark?.text ?? "").")
    }
}

// MARK: - Previews

#Preview {
    ScrollView {
        FatTab(payload: nil)
    }
    .background(Color.appBackground)
}
