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
            FatRatioCard(value: payload?.fat["fat_ratio"]?.numberValue ?? 24.8)
            
            VisceralSubcutaneousCard(
                visceralFat: payload?.fat["visceral_vs_subcutaneous"]?.nestedNumber("visceralFatDeltaKg") ?? 4.2,
                subcutaneousFat: payload?.fat["visceral_vs_subcutaneous"]?.nestedNumber("subcutaneousFatDeltaKg") ?? 15.8,
                verdict: payload?.fat["visceral_vs_subcutaneous"]?.title ?? "Mostly Subcutaneous",
                remark: payload?.fat["visceral_vs_subcutaneous"]?.displayComment ?? "Distribution is relatively safer, though total fat remains elevated."
            )
            
            VisceralSubcRatioTrendCard(
                currentRatio: 0.27,
                statusText: "Safe",
                statusColor: .goodGreen,
                statusIcon: "checkmark.circle.fill",
                remarkText: payload?.fat["fat_ratio_trend"]?.displayComment ?? "Visceral to subcutaneous ratio is within a healthy and safe range."
            )
            
            VisceralFatMassTrendCard(
                currentMass: payload?.fat["visceral_trend"]?.numberValue ?? 4.2,
                statusText: "Optimal",
                statusColor: .goodGreen,
                statusIcon: "checkmark.circle.fill",
                remarkText: payload?.fat["visceral_trend"]?.displayComment ?? "Visceral fat mass is within a healthy, low-risk range."
            )
            
            SubcFatMassTrendCard(
                currentMass: payload?.fat["subcutaneous_fat_mass_trend"]?.numberValue ?? 15.8,
                statusText: "Elevated",
                statusColor: .extremityRed,
                statusIcon: "exclamationmark.triangle.fill",
                remarkText: payload?.fat["subcutaneous_fat_mass_trend"]?.displayComment ?? "Subcutaneous fat mass is elevated. Focus on caloric deficit and activity."
            )
            
            FatMassTrendCard(
                currentMass: payload?.fat["fat_mass_trend"]?.numberValue ?? 20.0,
                statusText: "Elevated",
                remarkText: payload?.fat["fat_mass_trend"]?.displayComment ?? "Total fat mass is above target.",
                data: payload?.fat["fat_mass_trend"]?.trends["fatMassKg"]?.map { FatMassPoint(date: $0.date, value: $0.value) }
            )
            
            FatHistoryCard(
                value: payload?.fat["fat_ratio"]?.numberValue ?? 24.8,
                data: payload?.fat["fat_ratio"]?.trends["body_fat_pct"]?.map { FatDataPoint(date: $0.date, ratio: $0.value) }
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
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
    
    var metrics: FatRatioMetrics {
        FatRatioMetrics(value: value)
    }
    
    private let zones: [FatRatioZone] = [
        FatRatioZone(name: "Low", min: 2.0, max: 6.0, rangeText: "<6%", color: Color.extremityRed),
        FatRatioZone(name: "Optimal", min: 6.0, max: 18.0, rangeText: "6-18%", color: Color.goodGreen),
        FatRatioZone(name: "Average", min: 18.0, max: 25.0, rangeText: "18-25%", color: Color.avgYellow),
        FatRatioZone(name: "High", min: 25.0, max: 30.0, rangeText: "25%+", color: Color.extremityRed)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Top Section (Large Circular Gauge)
            ZStack {
                GeometryReader { geometry in
                    let size = geometry.size
                    let strokeWidth: CGFloat = 16
                    let currentPos = valuePosition(for: value, in: size)
                    
                    ZStack {
                        // Thin backdrop precision ring
                        Circle()
                            .trim(from: 0.0, to: 0.75)
                            .stroke(
                                Color.appSeparator.opacity(0.25),
                                style: StrokeStyle(lineWidth: 1, lineCap: .round)
                            )
                            .rotationEffect(.degrees(135))
                            .frame(width: size.width - strokeWidth, height: size.height - strokeWidth)
                            .position(x: size.width / 2, y: size.height / 2)
                        
                        // Track segments (background + active progress)
                        ForEach(0..<zones.count, id: \.self) { index in
                            let zone = zones[index]
                            
                            let startFraction = (zone.min - 2.0) / 28.0
                            let endFraction = (zone.max - 2.0) / 28.0
                            
                            let startTrim = 0.75 * startFraction
                            let endTrim = 0.75 * endFraction
                            
                            // Apply a gap between segments for precision look
                            let gapOffset: CGFloat = 0.005
                            let segmentStart = startTrim + (index > 0 ? gapOffset : 0)
                            let segmentEnd = endTrim - (index < zones.count - 1 ? gapOffset : 0)
                            
                            // 1. Background Track Segment (low opacity)
                            Circle()
                                .trim(from: segmentStart, to: segmentEnd)
                                .stroke(
                                    zone.color.opacity(0.12),
                                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt)
                                )
                                .rotationEffect(.degrees(135))
                                .frame(width: size.width - strokeWidth, height: size.height - strokeWidth)
                                .position(x: size.width / 2, y: size.height / 2)
                            
                            // 2. Active Progress Fill Segment
                            if value > zone.min {
                                let activeFraction = (min(zone.max, value) - 2.0) / 28.0
                                let activeEndTrim = 0.75 * activeFraction
                                let activeEnd = max(segmentStart, activeEndTrim - (index < zones.count - 1 && value >= zone.max ? gapOffset : 0))
                                
                                Circle()
                                    .trim(from: segmentStart, to: activeEnd)
                                    .stroke(
                                        zone.color.gradient,
                                        style: StrokeStyle(lineWidth: strokeWidth, lineCap: .butt)
                                    )
                                    .rotationEffect(.degrees(135))
                                    .frame(width: size.width - strokeWidth, height: size.height - strokeWidth)
                                    .position(x: size.width / 2, y: size.height / 2)
                                    .shadow(color: zone.color.opacity(0.15), radius: 3, x: 0, y: 1)
                            }
                        }
                        
                        // Numeric Labels at Interval Boundaries (2%, 6%, 18%, 25%, 30%)
                        Text("2%")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .position(valuePosition(for: 2.0, in: size, radiusOffset: -18))
                        
                        Text("6%")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .position(valuePosition(for: 6.0, in: size, radiusOffset: -18))
                        
                        Text("18% Target")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.goodGreen)
                            .position(valuePosition(for: 18.0, in: size, radiusOffset: -22))
                        
                        Text("25%")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .position(valuePosition(for: 25.0, in: size, radiusOffset: -18))
                        
                        Text("30%")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                            .position(valuePosition(for: 30.0, in: size, radiusOffset: -18))
                        
                        // Current Target Pointer (Green triangle pointing outwards at 18%)
                        Image(systemName: "triangle.fill")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.goodGreen)
                            .rotationEffect(Angle(degrees: valueAngle(for: 18.0).degrees + 90))
                            .position(valuePosition(for: 18.0, in: size, radiusOffset: -12))
                            .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 0.5)
                        
                        // Current Value indicator knob with statusColor glow & border
                        Circle()
                            .fill(Color.white)
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle().stroke(metrics.statusColor, lineWidth: 3)
                            )
                            .background(
                                Circle()
                                    .fill(metrics.statusColor)
                                    .frame(width: 24, height: 24)
                                    .blur(radius: 6)
                                    .opacity(0.6)
                            )
                            .position(currentPos)
                            .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 1.5)
                    }
                }
                
                // Inside Text HUD
                VStack(spacing: 6) {
                    Text("Fat Ratio")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                        .tracking(0.8)
                    
                    Text(metrics.valueText)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(Color.valueDarkTeal)
                    
                    Text(metrics.statusText)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(metrics.statusColor)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(metrics.statusColor.opacity(0.12))
                        )
                }
            }
            .frame(width: 200, height: 200)
            .padding(.top, 8)
            
            // Legend
            HStack(spacing: 8) {
                ForEach(zones, id: \.name) { zone in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(zone.color)
                            .frame(width: 6, height: 6)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(zone.name)
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.primary)
                            Text(zone.rangeText)
                                .font(.system(size: 8, weight: .medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(width: 280)
            
            // Horizontal Divider
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
                .padding(.horizontal, 4)
            
            // Bottom Section: Verdict & Remark
            HStack(alignment: .top, spacing: 16) {
                // Verdict Column
                VStack(alignment: .leading, spacing: 4) {
                    Text("VERDICT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    HStack(spacing: 6) {
                        Text(metrics.verdictText)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(metrics.statusColor)
                        
                        Image(systemName: metrics.statusIcon)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(metrics.statusColor)
                            .frame(width: 18, height: 18)
                            .background(
                                Circle()
                                    .stroke(metrics.statusColor, lineWidth: 1)
                            )
                    }
                }
                
                // Vertical Separator
                Color.appSeparator
                    .frame(width: 1)
                    .frame(height: 38)
                
                // Remark Column
                VStack(alignment: .leading, spacing: 4) {
                    Text("REMARK")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    Text(metrics.remarkText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 18)
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
        .accessibilityLabel("Fat Ratio, \(String(format: "%.1f", value)) percent, \(metrics.statusText.lowercased()), \(metrics.verdictText.lowercased()).")
    }
    
    // --- Helper Methods to Prevent Result Builder Bloat ---
    
    private func valuePosition(for value: Double, in size: CGSize, radiusOffset: CGFloat = 0) -> CGPoint {
        let centerX = size.width / 2
        let centerY = size.height / 2
        let strokeWidth: CGFloat = 16
        let arcRadius = (size.width - strokeWidth) / 2 + radiusOffset
        let valAngle = valueAngle(for: value).radians
        return CGPoint(
            x: centerX + arcRadius * CGFloat(cos(valAngle)),
            y: centerY + arcRadius * CGFloat(sin(valAngle))
        )
    }
    
    private func valueAngle(for value: Double) -> Angle {
        let clampedVal = max(2.0, min(30.0, value))
        let activeFraction = (clampedVal - 2.0) / 28.0
        return Angle(degrees: 135.0 + 270.0 * activeFraction)
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
    var reportData: [FatDataPoint]?
    
    var metrics: FatRatioMetrics {
        FatRatioMetrics(value: value)
    }
    
    init(value: Double = 24.8, data: [FatDataPoint]? = nil) {
        self.value = value
        self.reportData = data
    }

    var data: [FatDataPoint] {
        if let reportData, !reportData.isEmpty {
            return reportData
        }

        return [
            FatDataPoint(date: Calendar.current.date(byAdding: .day, value: -21, to: Date())!, ratio: 25.6),
            FatDataPoint(date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!, ratio: 25.2),
            FatDataPoint(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, ratio: 24.9),
            FatDataPoint(date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!, ratio: 24.8)
        ]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Fat Ratio History")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Steady downward trend over the past 4 weeks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Chart {
                ForEach(data) { point in
                    LineMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Ratio", point.ratio)
                    )
                    .foregroundStyle(Color.goodGreen.gradient)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Ratio", point.ratio)
                    )
                    .foregroundStyle(Color.goodGreen)
                    .annotation(position: .top, spacing: 4) {
                        Text(String(format: "%.1f%%", point.ratio))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYScale(domain: 24.0...26.5)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    AxisValueLabel(format: .dateTime.month().day())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel() {
                        if let doubleValue = value.as(Double.self) {
                            Text(String(format: "%.1f%%", doubleValue))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.top, 4)
            
            // Divider
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
                .padding(.horizontal, 4)
            
            // Bottom Verdict & Remark Row
            HStack(alignment: .top, spacing: 16) {
                // Verdict Column (Wraps to content width)
                VStack(alignment: .leading, spacing: 4) {
                    Text("VERDICT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    HStack(spacing: 6) {
                        Text(metrics.verdictText)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(metrics.statusColor)
                        
                        Image(systemName: metrics.statusIcon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(metrics.statusColor)
                            .frame(width: 18, height: 18)
                            .background(
                                Circle()
                                    .stroke(metrics.statusColor, lineWidth: 1)
                            )
                    }
                }
                
                // Vertical Separator
                Color.appSeparator
                    .frame(width: 1)
                    .frame(height: 38)
                
                // Remark Column (Fills remaining width)
                VStack(alignment: .leading, spacing: 4) {
                    Text("REMARK")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    Text(metrics.remarkText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
    let remark: String
    
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
            
            // Bottom Interpretation Panel
            HStack(alignment: .top, spacing: 12) {
                // Verdict Column
                VStack(alignment: .leading, spacing: 4) {
                    Text("VERDICT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    Text(verdict)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(Color.subcutaneousLightTeal)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Vertical Separator
                Color.appSeparator
                    .frame(width: 1)
                    .frame(height: 34)
                    .padding(.top, 2)
                
                // Remark Column
                VStack(alignment: .leading, spacing: 4) {
                    Text("REMARK")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    Text(remark)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 2)
            .padding(.top, 4)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
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
        .accessibilityLabel("Visceral fat \(String(format: "%.1f", visceralFat)) kilograms, \(visceralPercentageText). Subcutaneous fat \(String(format: "%.1f", subcutaneousFat)) kilograms, \(subcutaneousPercentageText). Verdict: \(verdict). Remark: \(remark.replacingOccurrences(of: "\n", with: " ")).")
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
    let remarkText: String
    var reportData: [FatMassPoint]?
    
    init(currentMass: Double, statusText: String, remarkText: String, data: [FatMassPoint]? = nil) {
        self.currentMass = currentMass
        self.statusText = statusText
        self.remarkText = remarkText
        self.reportData = data
    }

    var data: [FatMassPoint] {
        if let reportData, !reportData.isEmpty {
            return reportData
        }

        return [
            FatMassPoint(date: Calendar.current.date(byAdding: .day, value: -21, to: Date())!, value: 17.2),
            FatMassPoint(date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!, value: 19.0),
            FatMassPoint(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, value: 18.2),
            FatMassPoint(date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!, value: 20.0)
        ]
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
                
                Text("Upward trend over the past 4 weeks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Mass", point.value)
                    )
                    .foregroundStyle(Color.extremityRed)
                    .annotation(position: .top, spacing: 4) {
                        Text(String(format: "%.1f kg", point.value))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYScale(domain: 15.0...21.5)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    AxisValueLabel(format: .dateTime.month().day())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel() {
                        if let doubleValue = value.as(Double.self) {
                            Text(String(format: "%.0f kg", doubleValue))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.top, 4)
            
            // Divider
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
                .padding(.horizontal, 4)
            
            // Bottom Verdict & Remark Row
            HStack(alignment: .top, spacing: 16) {
                // Verdict Column (Wraps to content width)
                VStack(alignment: .leading, spacing: 4) {
                    Text("VERDICT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    HStack(spacing: 6) {
                        Text(statusText)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(Color.extremityRed)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(Color.extremityRed)
                            .frame(width: 18, height: 18)
                            .background(
                                Circle()
                                    .stroke(Color.extremityRed, lineWidth: 1)
                            )
                    }
                }
                
                // Vertical Separator
                Color.appSeparator
                    .frame(width: 1)
                    .frame(height: 38)
                
                // Remark Column (Fills remaining width)
                VStack(alignment: .leading, spacing: 4) {
                    Text("REMARK")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    Text(remarkText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityLabel("Fat mass history over past 4 weeks, ending at \(String(format: "%.1f", currentMass)) kilograms. Current status is \(statusText). Remark: \(remarkText.replacingOccurrences(of: "\n", with: " ")).")
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
    let remarkText: String
    
    let data: [VisceralSubcRatioPoint] = [
        VisceralSubcRatioPoint(date: Calendar.current.date(byAdding: .day, value: -21, to: Date())!, value: 0.25),
        VisceralSubcRatioPoint(date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!, value: 0.25),
        VisceralSubcRatioPoint(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, value: 0.25),
        VisceralSubcRatioPoint(date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!, value: 0.27)
    ]
    
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
                
                Text("Healthy distribution maintained.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Ratio", point.value)
                    )
                    .foregroundStyle(Color.visceralDarkTeal)
                    .annotation(position: .top, spacing: 4) {
                        Text(String(format: "%.2f", point.value))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYScale(domain: 0.20...0.35)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    AxisValueLabel(format: .dateTime.month().day())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel() {
                        if let doubleValue = value.as(Double.self) {
                            Text(String(format: "%.2f", doubleValue))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.top, 4)
            
            // Divider
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
                .padding(.horizontal, 4)
            
            // Bottom Verdict & Remark Row
            HStack(alignment: .top, spacing: 16) {
                // Verdict Column (Wraps to content width)
                VStack(alignment: .leading, spacing: 4) {
                    Text("VERDICT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    HStack(spacing: 6) {
                        Text(statusText)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(statusColor)
                        
                        Image(systemName: statusIcon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(statusColor)
                            .frame(width: 18, height: 18)
                            .background(
                                Circle()
                                    .stroke(statusColor, lineWidth: 1)
                            )
                    }
                }
                
                // Vertical Separator
                Color.appSeparator
                    .frame(width: 1)
                    .frame(height: 38)
                
                // Remark Column (Fills remaining width)
                VStack(alignment: .leading, spacing: 4) {
                    Text("REMARK")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    Text(remarkText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityLabel("Visceral to subcutaneous ratio history, ending at \(String(format: "%.2f", currentRatio)). Current status is \(statusText). Remark: \(remarkText).")
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
    let remarkText: String
    
    let data: [SubcFatMassPoint] = [
        SubcFatMassPoint(date: Calendar.current.date(byAdding: .day, value: -21, to: Date())!, value: 13.8),
        SubcFatMassPoint(date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!, value: 15.2),
        SubcFatMassPoint(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, value: 14.6),
        SubcFatMassPoint(date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!, value: 15.8)
    ]
    
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
                
                Text("Upward trend over the past 4 weeks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Mass", point.value)
                    )
                    .foregroundStyle(Color.subcutaneousLightTeal)
                    .annotation(position: .top, spacing: 4) {
                        Text(String(format: "%.1f kg", point.value))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYScale(domain: 12.0...18.0)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    AxisValueLabel(format: .dateTime.month().day())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel() {
                        if let doubleValue = value.as(Double.self) {
                            Text(String(format: "%.0f kg", doubleValue))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.top, 4)
            
            // Divider
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
                .padding(.horizontal, 4)
            
            // Bottom Verdict & Remark Row
            HStack(alignment: .top, spacing: 16) {
                // Verdict Column (Wraps to content width)
                VStack(alignment: .leading, spacing: 4) {
                    Text("VERDICT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    HStack(spacing: 6) {
                        Text(statusText)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(statusColor)
                        
                        Image(systemName: statusIcon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(statusColor)
                            .frame(width: 18, height: 18)
                            .background(
                                Circle()
                                    .stroke(statusColor, lineWidth: 1)
                            )
                    }
                }
                
                // Vertical Separator
                Color.appSeparator
                    .frame(width: 1)
                    .frame(height: 38)
                
                // Remark Column (Fills remaining width)
                VStack(alignment: .leading, spacing: 4) {
                    Text("REMARK")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    Text(remarkText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityLabel("Subcutaneous fat mass history, ending at \(String(format: "%.1f", currentMass)) kilograms. Current status is \(statusText). Remark: \(remarkText).")
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
    let remarkText: String
    
    let data: [VisceralFatMassPoint] = [
        VisceralFatMassPoint(date: Calendar.current.date(byAdding: .day, value: -21, to: Date())!, value: 3.4),
        VisceralFatMassPoint(date: Calendar.current.date(byAdding: .day, value: -14, to: Date())!, value: 3.8),
        VisceralFatMassPoint(date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!, value: 3.6),
        VisceralFatMassPoint(date: Calendar.current.date(byAdding: .day, value: 0, to: Date())!, value: 4.2)
    ]
    
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
                
                Text("Slightly upward trend over the past 4 weeks.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
                    .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                    
                    PointMark(
                        x: .value("Date", point.date, unit: .day),
                        y: .value("Mass", point.value)
                    )
                    .foregroundStyle(Color.visceralDarkTeal)
                    .annotation(position: .top, spacing: 4) {
                        Text(String(format: "%.1f kg", point.value))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .chartYScale(domain: 2.0...6.0)
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { value in
                    AxisValueLabel(format: .dateTime.month().day())
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                        .foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel() {
                        if let doubleValue = value.as(Double.self) {
                            Text(String(format: "%.0f kg", doubleValue))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .frame(height: 200)
            .padding(.top, 4)
            
            // Divider
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
                .padding(.horizontal, 4)
            
            // Bottom Verdict & Remark Row
            HStack(alignment: .top, spacing: 16) {
                // Verdict Column (Wraps to content width)
                VStack(alignment: .leading, spacing: 4) {
                    Text("VERDICT")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    HStack(spacing: 6) {
                        Text(statusText)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(statusColor)
                        
                        Image(systemName: statusIcon)
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(statusColor)
                            .frame(width: 18, height: 18)
                            .background(
                                Circle()
                                    .stroke(statusColor, lineWidth: 1)
                            )
                    }
                }
                
                // Vertical Separator
                Color.appSeparator
                    .frame(width: 1)
                    .frame(height: 38)
                
                // Remark Column (Fills remaining width)
                VStack(alignment: .leading, spacing: 4) {
                    Text("REMARK")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.secondary)
                        .tracking(1.0)
                    
                    Text(remarkText)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
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
        .accessibilityLabel("Visceral fat mass history, ending at \(String(format: "%.1f", currentMass)) kilograms. Current status is \(statusText). Remark: \(remarkText).")
    }
}

// MARK: - Previews

#Preview {
    ScrollView {
        FatTab(payload: nil)
    }
    .background(Color.appBackground)
}
