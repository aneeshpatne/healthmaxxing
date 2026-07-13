import SwiftUI
import Charts

struct MuscleTab: View {
    let payload: InsightReportPayload?

    private var sections: [InsightReportMetricSection] {
        ["muscle_mass", "bone_mass_trend", "muscle_ratio_trend", "skeletal_muscle_mass_trend"]
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
        .padding(.horizontal, FormaSpacing.screenGutter)
        .padding(.vertical, 16)
    }
}

private struct MuscleReportCard: View {
    let section: InsightReportMetricSection

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FormaCardHeader(section.displayTitle) {
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
                let chartPoints = trendPoints.sorted { $0.date < $1.date }

                FormaTimeSeriesChart(
                    points: chartPoints.map {
                        FormaChartPoint(
                            date: $0.date,
                            value: $0.value,
                            metric: section.displayTitle,
                            color: FormaChartMetric.infer(from: section.displayTitle).color
                        )
                    }
                )
            }

            // Bottom Remark Row
            if let remark = section.remark {
                Rectangle()
                    .fill(Color.appSeparator)
                    .frame(height: 1)
                    .padding(.horizontal, 4)
                
                FormaCallout(
                    text: remark.text ?? "",
                    systemImage: remark.marker?.iconName ?? "sparkle",
                    tint: remark.marker?.color ?? Color.sleekAccent
                )
                .padding(.horizontal, 4)
            }
        }
        .formaMetricCard()
    }
}
