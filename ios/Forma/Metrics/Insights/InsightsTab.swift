import SwiftUI
import Charts

struct InsightsTab: View {
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                // MARK: - Weekly Summary Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 24, height: 24)
                            .background(Color.accentColor.opacity(0.1), in: Circle())

                        Text("Weekly Summary")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Spacer()

                        Text("Jun 16 – 22")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.fill.tertiary, in: Capsule())
                    }

                    // Insight text
                    Text("Foundation is strong — body fat trending down while lean mass holds steady.")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .background(.secondary.opacity(0.1))

                    // Premium simplified insight row
                    HStack(spacing: 14) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.orange)
                            .frame(width: 38, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.orange.opacity(0.12))
                            )

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Body Fat")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text("Down 0.4% this week")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Apple Health style trend badge
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.right")
                                .font(.system(size: 11, weight: .bold))
                            Text("-0.4%")
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.green.opacity(0.1), in: Capsule())
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.appSecondaryBackground)
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 16)

                // MARK: - Strong Base Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 24, height: 24)
                            .background(.green.opacity(0.12), in: Circle())

                        Text("Strong Base")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Spacer()
                    }

                    // Headline
                    Text("54.6 kg of lean mass gives you a strong foundation")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body
                    Text("At 172 cm, your current muscle base supports a strong, athletic look as you continue leaning out.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .background(.secondary.opacity(0.1))

                    // Insight row
                    HStack(spacing: 14) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 38, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.green.opacity(0.12))
                            )

                        Text("Keep protein intake steady and stay consistent with strength training to maintain this muscle.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.appSecondaryBackground)
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 16)

                // MARK: - Progress Trend Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 24, height: 24)
                            .background(.green.opacity(0.12), in: Circle())

                        Text("Progress Trend")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Spacer()
                    }

                    // Headline
                    Text("Body fat is moving down across every view")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body
                    Text("Subcutaneous fat is down 0.89 kg over the last 30 days, while overall fat markers continue trending lower.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Chart card
                    ProgressTrendChart()

                    Divider()
                        .background(.secondary.opacity(0.1))

                    // Insight row
                    HStack(spacing: 14) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 38, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.green.opacity(0.85))
                            )

                        Text("Steady progress like this is a strong sign your current rhythm is working. Keep the pace consistent.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.appSecondaryBackground)
                        .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 4)
                )
                .padding(.horizontal, 16)
            }
        }
    }
}

// MARK: - Progress Trend Chart

private struct ProgressTrendChart: View {
    private let data: [FatMetric] = [
        // Body Fat %
        FatMetric(date: "May 24", value: 18.5, metric: "Body Fat %"),
        FatMetric(date: "May 31", value: 18.2, metric: "Body Fat %"),
        FatMetric(date: "Jun 7", value: 18.0, metric: "Body Fat %"),
        FatMetric(date: "Jun 14", value: 17.9, metric: "Body Fat %"),
        FatMetric(date: "Jun 22", value: 17.8, metric: "Body Fat %"),

        // Subcut. Fat %
        FatMetric(date: "May 24", value: 14.2, metric: "Subcut. Fat %"),
        FatMetric(date: "May 31", value: 14.0, metric: "Subcut. Fat %"),
        FatMetric(date: "Jun 7", value: 13.7, metric: "Subcut. Fat %"),
        FatMetric(date: "Jun 14", value: 13.5, metric: "Subcut. Fat %"),
        FatMetric(date: "Jun 22", value: 13.4, metric: "Subcut. Fat %"),

        // Visceral Fat
        FatMetric(date: "May 24", value: 8.5, metric: "Visceral Fat"),
        FatMetric(date: "May 31", value: 8.3, metric: "Visceral Fat"),
        FatMetric(date: "Jun 7", value: 8.1, metric: "Visceral Fat"),
        FatMetric(date: "Jun 14", value: 7.9, metric: "Visceral Fat"),
        FatMetric(date: "Jun 22", value: 7.8, metric: "Visceral Fat")
    ]

    private let metrics = [
        ("Body Fat %", Color.green),
        ("Subcut. Fat %", Color.blue),
        ("Visceral Fat", Color.orange)
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Legend
            HStack(spacing: 16) {
                ForEach(metrics, id: \.0) { metric, color in
                    HStack(spacing: 6) {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)

                        Text(metric)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            // Chart
            Chart(data) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Value", item.value)
                )
                .foregroundStyle(by: .value("Metric", item.metric))
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
            }
            .chartForegroundStyleScale([
                "Body Fat %": Color.green,
                "Subcut. Fat %": Color.blue,
                "Visceral Fat": Color.orange
            ])
            .chartLegend(.hidden)
            .chartYAxis(.hidden)
            .frame(height: 160)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.appSecondaryBackground.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.secondary.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct FatMetric: Identifiable {
    let id = UUID()
    let date: String
    let value: Double
    let metric: String
}

#Preview {
    InsightsTab()
        .padding(.vertical, 20)
        .background(Color.appBackground)
}
