import SwiftUI
import Charts

struct MuscleTab: View {
    let payload: InsightReportPayload?

    private var sections: [InsightReportMetricSection] {
        ["muscle_mass", "bone_mass_trend", "muscle_mass_trend", "skeletal_muscle_mass_trend"]
            .compactMap { payload?.muscle[$0] }
    }

    var body: some View {
        VStack(spacing: 20) {
            if sections.isEmpty {
                MetricsUnavailableContent(message: "Muscle report data is unavailable.")
            } else {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    MuscleReportCard(section: section)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

private struct MuscleReportCard: View {
    let section: InsightReportMetricSection

    private func yDomain(for points: [InsightReportTrendPoint]) -> ClosedRange<Double> {
        let values = points.map { $0.value }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 0...100
        }
        if minVal == maxVal {
            return (minVal - 1.5)...(maxVal + 1.5)
        }
        return (minVal - 1.5)...(maxVal + 1.5)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header Row
            HStack(spacing: 10) {
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Color.sleekAccent)
                    .frame(width: 26, height: 26)
                    .background(Color.sleekAccent.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text(section.displayTitle)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(1.0)

                Spacer()

                if let value = section.numberValue {
                    Text(String(format: "%.1f", value))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                }
            }

            // Description / Comment
            VStack(alignment: .leading, spacing: 4) {
                if let title = section.title, title != section.displayTitle {
                    Text(title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if !section.displayComment.isEmpty {
                    Text(section.displayComment)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            // Swift Chart Plot
            if let trendPoints = section.trends.first?.value, !trendPoints.isEmpty {
                Chart {
                    ForEach(trendPoints, id: \.createdAt) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Value", point.value)
                        )
                        .foregroundStyle(Color.sleekAccent.gradient)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                    
                    if let lastPoint = trendPoints.last {
                        PointMark(
                            x: .value("Date", lastPoint.date),
                            y: .value("Value", lastPoint.value)
                        )
                        .foregroundStyle(Color.sleekAccent)
                        .symbol {
                            Circle()
                                .fill(Color.sleekAccent)
                                .frame(width: 8, height: 8)
                                .overlay(Circle().stroke(Color.white, lineWidth: 2))
                                .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                        }
                    }
                }
                .chartYScale(domain: yDomain(for: trendPoints))
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .leading) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                            .foregroundStyle(.secondary.opacity(0.15))
                        AxisValueLabel()
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(height: 160)
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

            // Bottom Remark Row
            if let remark = section.remark {
                Rectangle()
                    .fill(Color.appSeparator)
                    .frame(height: 1)
                    .padding(.horizontal, 4)
                
                HStack(alignment: .top, spacing: 14) {
                    let marker = remark.marker
                    Image(systemName: marker?.iconName ?? "sparkle")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(marker?.color ?? Color.sleekAccent)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill((marker?.color ?? Color.sleekAccent).opacity(0.12))
                        )
                    
                    Text(remark.text ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    Spacer()
                }
                .padding(.horizontal, 4)
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
    }
}
