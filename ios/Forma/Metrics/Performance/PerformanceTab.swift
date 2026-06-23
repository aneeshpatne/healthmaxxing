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

struct PerformanceTab: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                FFMIGaugeCard()
                CompositionMapCard()
                BodyCompositionFlowCard()
                CompositionTrendsCard()
                RecompVectorPlotCard()
                ExcessFatGaugeCard()
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
    }
}

// MARK: - FFMI Gauge Card

struct FFMIGaugeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("FFMI Gauge")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Fat-Free Mass Index measures your muscle mass relative to height.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Gauge Visualization & Score
            FFMISemicircularGauge(value: 19.5)
                .padding(.top, 10)
                .padding(.horizontal, 10)
            
            // Category legend
            FFMICategoryLegend(selectedValue: 19.5)
                .padding(.top, 4)
            
            // Subtle separator
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
            
            // Insight text
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.performancePrimary.gradient)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.performancePrimary.opacity(0.12))
                    )
                
                Text("FFMI around 20 reflects a well-trained frame with room to reveal more definition as fat comes down.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
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
        .padding(.horizontal, 16)
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
                        .tracking(1.0)
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
    PerformanceTab()
        .padding(.vertical, 20)
        .background(Color.appBackground)
}

// MARK: - Composition Map Card

struct CompositionMapCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Composition Map")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Compare your Fat-Free Mass Index (muscle) against your Fat Mass Index (fat).")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Main Chart Area
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    // Y Axis Label
                    Text("FMI — Fat Mass")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .fixedSize()
                        .rotationEffect(.degrees(-90))
                        .frame(width: 16)
                    
                    CompositionQuadrantChart(ffmi: 19.52, fmi: 6.42)
                }
                
                // X Axis Label
                Text("FFMI — Muscle Mass")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.leading, 28) // Offset to align with chart
            }
            .padding(.vertical, 8)
            
            // Legend
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.performancePrimary.gradient)
                    .frame(width: 10, height: 10)
                
                Text("Your Position (19.52, 6.42)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            // Subtle separator
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
            
            // Insight text
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "map.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.performancePrimary.gradient)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.performancePrimary.opacity(0.12))
                    )
                
                Text("Your lean mass is well-developed. Lowering fat mass will make your muscle definition more visible.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
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
        .padding(.horizontal, 16)
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
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 1)
        )
    }
}

// MARK: - Body Composition Flow Card

struct BodyCompositionFlowCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Body Composition Flow")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Breaks down your total body weight into lean mass and fat mass.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Flow Diagram
            HStack(spacing: 0) {
                // Source Node
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Weight")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Color.performancePrimary)
                    Text("76.75 kg")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 14)
                .frame(width: 115, height: 76, alignment: .leading)
                .background(Color.performancePrimary.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
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
                    let leftSplitY = leftTopY + (boxHeight * 0.75) // 75% lean, 25% fat
                    
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
                            Text("57.75 kg")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text("75.2%")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 76)
                    .background(Color.performancePositive.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color.performancePositive.opacity(0.2), lineWidth: 1)
                    )
                    
                    // Fat Mass
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Fat Mass")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Color.performanceNegative)
                        
                        HStack(spacing: 4) {
                            Text("19.00 kg")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text("24.8%")
                                .font(.caption2.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 76)
                    .background(Color.performanceNegative.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
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
            
            // Insight text
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.performancePrimary.gradient)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.performancePrimary.opacity(0.12))
                    )
                
                Text("Lean mass is solid, fat mass is trending downward, and the ratio is improving over time.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
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
        .padding(.horizontal, 16)
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
    let id = UUID()
    let date: String
    let value: Double
    let metric: String
}

struct CompositionTrendsCard: View {
    private let trendData: [CompositionTrend] = [
        // Lean Mass
        CompositionTrend(date: "May 24", value: 0.0, metric: "Lean Mass"),
        CompositionTrend(date: "May 31", value: 0.12, metric: "Lean Mass"),
        CompositionTrend(date: "Jun 7", value: -0.05, metric: "Lean Mass"),
        CompositionTrend(date: "Jun 14", value: 0.08, metric: "Lean Mass"),
        CompositionTrend(date: "Jun 22", value: 0.02, metric: "Lean Mass"),
        
        // Fat Mass
        CompositionTrend(date: "May 24", value: 0.0, metric: "Fat Mass"),
        CompositionTrend(date: "May 31", value: -0.15, metric: "Fat Mass"),
        CompositionTrend(date: "Jun 7", value: -0.28, metric: "Fat Mass"),
        CompositionTrend(date: "Jun 14", value: -0.38, metric: "Fat Mass"),
        CompositionTrend(date: "Jun 22", value: -0.48, metric: "Fat Mass")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Composition Trends")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Track changes in your lean mass and fat mass from your baseline.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Chart Area
            VStack(alignment: .leading, spacing: 14) {
                // Legend
                HStack(spacing: 14) {
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.performancePositive)
                            .frame(width: 10, height: 3)
                        
                        Text("Lean Mass")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(Color.performanceNegative)
                            .frame(width: 10, height: 3)
                        
                        Text("Fat Mass")
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
                
                // Chart
                Chart(trendData) { item in
                    LineMark(
                        x: .value("Date", item.date),
                        y: .value("Change", item.value)
                    )
                    .foregroundStyle(by: .value("Metric", item.metric))
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .interpolationMethod(.catmullRom)
                    
                    // Endpoint markers
                    if item.date == "Jun 22" {
                        PointMark(
                            x: .value("Date", item.date),
                            y: .value("Change", item.value)
                        )
                        .foregroundStyle(by: .value("Metric", item.metric))
                        .symbol {
                            Circle()
                                .fill(item.metric == "Lean Mass" ? Color.performancePositive : Color.performanceNegative)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Lean Mass": Color.performancePositive,
                    "Fat Mass": Color.performanceNegative
                ])
                .chartLegend(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                            .foregroundStyle(.secondary.opacity(0.15))
                        
                        // Bold the zero line
                        if let yValue = value.as(Double.self), yValue == 0 {
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 1))
                                .foregroundStyle(.secondary.opacity(0.4))
                        }
                        
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(height: 180)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.appTertiaryBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.appSeparator, lineWidth: 0.5)
            )
            
            // Subtle separator
            Rectangle()
                .fill(Color.appSeparator)
                .frame(height: 1)
            
            // Insight text
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "chart.line.downtrend.xyaxis")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.performanceNegative.gradient)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.performanceNegative.opacity(0.12))
                    )
                
                Text("Fat mass is down 0.48 kg over the last 30 days, while lean mass is essentially unchanged.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
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
        .padding(.horizontal, 16)
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
    private let vectorData: [VectorPoint] = [
        VectorPoint(fat: 20.0, lean: 57.0, phase: "History"),
        VectorPoint(fat: 19.0, lean: 57.8, phase: "History"),
        VectorPoint(fat: 19.0, lean: 57.8, phase: "Future"),
        VectorPoint(fat: 12.7, lean: 57.7, phase: "Future")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            RecompVectorHeader()
            RecompVectorChart(vectorData: vectorData)
            RecompWeightSummary()
            RecompVectorInsight()
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
        .padding(.horizontal, 16)
    }
}

private struct RecompVectorHeader: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Recomp Vector Plot")
                .font(.headline)
                .foregroundStyle(.primary)

            Text("Track your body composition journey across distinct zones.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct RecompVectorChart: View {
    let vectorData: [VectorPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Chart {
                RecompLineMarks(vectorData: vectorData)
                RecompArrowMark()
                RecompStartMark()
                RecompCurrentMark()
                RecompTargetMark()
                }
                .chartForegroundStyleScale([
                    "History": Color.gray.opacity(0.5),
                    "Future": Color.performancePositive
                ])
                .chartLineStyleScale([
                    "History": StrokeStyle(lineWidth: 1.5),
                    "Future": StrokeStyle(lineWidth: 2.5, dash: [4, 4])
                ])
                .chartLegend(.hidden)
                .chartXScale(domain: 10.0...22.0)
                .chartYScale(domain: 55.0...60.0)
                .chartXAxisLabel("Fat Mass (kg)", position: .bottom, alignment: .center)
                .chartYAxisLabel("Lean Mass (kg)", position: .leading, alignment: .center)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 6)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(.secondary.opacity(0.15))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .chartYAxis {
                    AxisMarks(values: .automatic(desiredCount: 5)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4, 4]))
                            .foregroundStyle(.secondary.opacity(0.15))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(height: 220)
                .padding(.top, 10)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.appTertiaryBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.appSeparator, lineWidth: 0.5)
        )
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
        }
    }
}

private struct RecompArrowMark: ChartContent {
    var body: some ChartContent {
        PointMark(x: .value("Fat", 15.85), y: .value("Lean", 57.75))
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
    var body: some ChartContent {
        PointMark(x: .value("Fat", 20.0), y: .value("Lean", 57.0))
            .foregroundStyle(.gray)
            .symbolSize(80)
            .annotation(position: .bottom) {
                Text("Start")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.gray)
            }
    }
}

private struct RecompCurrentMark: ChartContent {
    var body: some ChartContent {
        PointMark(x: .value("Fat", 19.0), y: .value("Lean", 57.8))
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
    var body: some ChartContent {
        PointMark(x: .value("Fat", 12.7), y: .value("Lean", 57.7))
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

private struct RecompWeightSummary: View {
    var body: some View {
        HStack {
            Spacer()

            weight(label: "Current Weight", value: "76.8 kg")
            Spacer()

            Image(systemName: "arrow.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.performancePositive)

            Spacer()
            weight(label: "Target Weight", value: "70.4 kg")
            Spacer()
        }
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.performancePositive.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
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

private struct RecompVectorInsight: View {
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "target")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.performancePositive.gradient)
                .frame(width: 36, height: 36)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.performancePositive.opacity(0.12))
                )

            Text("There is a 6.3 kg fat-loss target between your current and goal physique, well within reach at your current trajectory.")
                .font(.subheadline)
                .foregroundStyle(.primary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }
}

// MARK: - Excess Fat Gauge Card

struct ExcessFatGaugeCard: View {
    let currentFat: Double = 19.0
    let targetFat: Double = 12.7
    
    var excessFat: Double { currentFat - targetFat }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 6) {
                Text("Excess Fat Gauge")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Compare your current fat mass against your target fat mass.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
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
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "flame")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.performanceCaution.gradient)
                    .frame(width: 36, height: 36)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.performanceCaution.opacity(0.12))
                    )
                
                Text("The gap between current and target fat is clear and closeable. Every 0.5 kg drop moves you visibly closer.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
            }
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
        .padding(.horizontal, 16)
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
            
            let targetFraction = target / current
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
                        .tracking(1.5)
                }
                .position(x: width / 2, y: height - 20)
            }
        }
        .aspectRatio(2.0, contentMode: .fit)
    }
}
