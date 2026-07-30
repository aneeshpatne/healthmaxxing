import SwiftUI

struct InsightsTab: View {
    @ObservedObject var reportStore: MetricsReportStore

    private var reportPayload: InsightReportPayload? {
        reportStore.payload
    }
    private var effortScore: Double? {
        reportPayload?.effortScore?.score.map { min(100, max(0, $0)) }
    }

    var body: some View {
        // Match Fat and Muscle: defer off-screen narrative cards and charts.
        LazyVStack(spacing: FormaSpacing.cardGap) {
            if let factor = reportPayload?.factor {
                PriorityFactorCard(factor: factor)
                    .formaEntrance(order: 0)
            }

            if let overview = reportPayload?.overview {
                InsightSectionCard(
                    title: overview.title ?? overview.displayTitle,
                    headline: overview.headline ?? overview.displayComment,
                    calloutText: overview.remark?.text ?? overview.displayComment,
                    calloutIcon: overview.remark?.marker?.iconName ?? "flame.fill",
                    calloutTint: overview.remark?.marker?.color ?? .formaAmber
                )
            }

            if let foundation = reportPayload?.foundation {
                InsightSectionCard(
                    title: foundation.title ?? foundation.displayTitle,
                    headline: foundation.headline ?? foundation.displayComment,
                    body: foundation.comment ?? foundation.remark?.text,
                    calloutText: foundation.remark?.text ?? foundation.displayComment,
                    calloutIcon: foundation.remark?.marker?.iconName ?? "checkmark.circle.fill",
                    calloutTint: foundation.remark?.marker?.color ?? .formaTeal
                )
            }

            if let momentum = reportPayload?.momentum {
                InsightSectionCard(
                    title: momentum.title ?? momentum.displayTitle,
                    headline: momentum.headline ?? momentum.displayComment,
                    body: momentum.comment ?? momentum.remark?.text,
                    calloutText: momentum.remark?.text ?? momentum.displayComment,
                    calloutIcon: momentum.remark?.marker?.iconName ?? "bolt.fill",
                    calloutTint: momentum.remark?.marker?.color ?? .formaAmber
                )
            }

            if let progress = reportPayload?.progress {
                InsightSectionCard(
                    title: progress.title ?? progress.displayTitle,
                    headline: progress.headline ?? progress.displayComment,
                    body: progress.comment ?? progress.remark?.text,
                    calloutText: progress.remark?.text ?? progress.displayComment,
                    calloutIcon: progress.remark?.marker?.iconName ?? "sparkle",
                    calloutTint: progress.remark?.marker?.color ?? .formaTeal
                ) {
                    ProgressTrendChart(trendData: progress.trendData)
                }
            }

            if let lever = reportPayload?.lever {
                InsightSectionCard(
                    title: lever.title ?? lever.displayTitle,
                    headline: lever.headline ?? lever.displayComment,
                    body: lever.comment ?? lever.remark?.text,
                    calloutText: lever.remark?.text ?? lever.displayComment,
                    calloutIcon: lever.remark?.marker?.iconName ?? "arrow.up.forward.circle.fill",
                    calloutTint: lever.remark?.marker?.color ?? .formaTeal
                )
            }

            if let physiqueArchetype = reportPayload?.physiqueArchetype {
                InsightSectionCard(
                    title: physiqueArchetype.title ?? "Physique",
                    headline: physiqueArchetype.headline ?? physiqueArchetype.comment,
                    body: physiqueArchetype.comment,
                    calloutText: physiqueArchetype.bodyType.map { "Body type: \($0.displayName)" } ?? physiqueArchetype.comment ?? "",
                    calloutIcon: "dumbbell.fill",
                    calloutTint: .formaCyan
                ) {
                    Image(physiqueArchetype.bodyType?.imageName ?? "body-normal")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .formaSurface(.chart, padding: nil)
                        .accessibilityLabel("\(physiqueArchetype.bodyType?.displayName ?? "Typical") body type illustration")
                }
            }

            if let effortScore, let effortSection = reportPayload?.effortScore {
                EffortScoreCard(
                    score: effortScore,
                    title: effortSection.title ?? "Effort Score",
                    calloutText: effortSection.comment ?? effortSection.remark?.text ?? "",
                    calloutIcon: effortSection.remark?.marker?.iconName ?? "chart.line.downtrend.xyaxis",
                    calloutTint: effortSection.remark?.marker?.color ?? .formaTeal
                )
            }
        }
        .padding(.top, FormaSpacing.xxs)
        .padding(.bottom, FormaSpacing.xl)
        .padding(.horizontal, FormaSpacing.screenGutter)
    }
}

// MARK: - Priority Factor (hero)

/// The leading insight, presented as a hero moment washed in its pastel factor color.
private struct PriorityFactorCard: View {
    let factor: InsightReportFactorSection

    private var tint: Color {
        factor.remark?.marker?.color ?? factor.factorColor?.color ?? .formaAmber
    }
    private var calloutText: String {
        factor.remark?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader(factor.displayTitle) {
                if let value = factor.value {
                    FormaValueBadge(
                        text: factor.formattedValue(value),
                        tint: factor.factorColor?.color ?? .sleekAccent
                    )
                }
            }

            if let comment = factor.comment, !comment.isEmpty {
                Text(comment)
                    .font(FormaTypography.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(FormaSpacing.xxs)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !calloutText.isEmpty, calloutText != factor.comment {
                FormaDivider()

                FormaCallout(
                    text: calloutText,
                    systemImage: factor.remark?.marker?.iconName ?? "target",
                    tint: tint
                )
            }
        }
        .formaSurface(.hero, padding: FormaSpacing.cardInset, tint: tint)
    }
}

// MARK: - Unified section card

/// One consistent layout for every narrative insight: title, optional headline and
/// body, optional visual content, then a divider and the pastel callout row.
private struct InsightSectionCard<Content: View>: View {
    let title: String
    var headline: String?
    var bodyText: String?
    let calloutText: String
    var calloutIcon = "sparkles"
    var calloutTint: Color = .sleekAccent
    @ViewBuilder var content: Content

    init(
        title: String,
        headline: String? = nil,
        body bodyText: String? = nil,
        calloutText: String,
        calloutIcon: String = "sparkles",
        calloutTint: Color = .sleekAccent,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.headline = headline
        self.bodyText = bodyText
        self.calloutText = calloutText
        self.calloutIcon = calloutIcon
        self.calloutTint = calloutTint
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader(title)

            if let headline, !headline.isEmpty, headline != calloutText {
                Text(headline)
                    .font(FormaTypography.sectionHeadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(FormaSpacing.xxs)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let bodyText, !bodyText.isEmpty, bodyText != headline, bodyText != calloutText {
                Text(bodyText)
                    .font(FormaTypography.body)
                    .foregroundStyle(.secondary)
                    .lineSpacing(FormaSpacing.xxs)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if Content.self != EmptyView.self {
                content
            }

            if shouldShowCallout {
                FormaDivider()

                FormaCallout(text: calloutText, systemImage: calloutIcon, tint: calloutTint)
            }
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
    }

    private var shouldShowCallout: Bool {
        let trimmed = calloutText.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed != headline && trimmed != bodyText
    }
}

extension InsightSectionCard where Content == EmptyView {
    init(
        title: String,
        headline: String? = nil,
        body bodyText: String? = nil,
        calloutText: String,
        calloutIcon: String = "sparkles",
        calloutTint: Color = .sleekAccent
    ) {
        self.init(
            title: title,
            headline: headline,
            body: bodyText,
            calloutText: calloutText,
            calloutIcon: calloutIcon,
            calloutTint: calloutTint
        ) { EmptyView() }
    }
}

// MARK: - Effort score

private struct EffortScoreCard: View {
    let score: Double
    let title: String
    let calloutText: String
    var calloutIcon = "chart.line.downtrend.xyaxis"
    var calloutTint: Color = .formaTeal

    var body: some View {
        VStack(alignment: .leading, spacing: FormaSpacing.cardContent) {
            FormaCardHeader(title) {
                FormaValueBadge(text: String(format: "%.0f/100", score), tint: .sleekAccent)
            }

            // Single-accent progress track with the current position marker.
            VStack(spacing: FormaSpacing.xs) {
                GeometryReader { geometry in
                    let markerRadius: CGFloat = 8
                    let markerX = min(
                        geometry.size.width - markerRadius,
                        max(markerRadius, geometry.size.width * CGFloat(score / 100))
                    )

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.appTertiaryBackground)
                            .frame(height: 8)

                        Capsule()
                            .fill(Color.sleekAccent.gradient)
                            .frame(width: max(markerRadius * 2, markerX), height: 8)

                        Circle()
                            .fill(Color.appSecondaryBackground)
                            .frame(width: markerRadius * 2, height: markerRadius * 2)
                            .overlay {
                                Circle()
                                    .stroke(Color.sleekAccent, lineWidth: 3)
                            }
                            .shadow(color: .black.opacity(0.18), radius: 3, y: 1)
                            .position(x: markerX, y: markerRadius)
                    }
                }
                .frame(height: 16)

                HStack {
                    Text("0")
                    Spacer()
                    Text("100")
                }
                .font(FormaTypography.micro)
                .foregroundStyle(.tertiary)
            }
            .padding(.vertical, FormaSpacing.xxs)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Effort score")
            .accessibilityValue("\(String(format: "%.0f", score)) out of 100")

            FormaDivider()

            FormaCallout(text: calloutText, systemImage: calloutIcon, tint: calloutTint)
        }
        .formaSurface(.card, padding: FormaSpacing.cardInset)
    }
}

private extension InsightReportSection {
    var displayTitle: String {
        title ?? headline ?? "Report"
    }

    var displayComment: String {
        comment ?? remark?.text ?? headline ?? ""
    }
}

private extension InsightReportFactorSection {
    var displayTitle: String {
        if let factor {
            return factor.displayTrendLabel
        }
        return "Priority Factor"
    }

    func formattedValue(_ value: Double) -> String {
        switch factor {
        case "body_fat_pct", "fatPercent":
            return String(format: "%.1f%%", value)
        default:
            return String(format: value.truncatingRemainder(dividingBy: 1) == 0 ? "%.0f" : "%.1f", value)
        }
    }
}

private extension InsightReportProgressSection {
    var displayTitle: String {
        title ?? headline ?? "Report"
    }

    var displayComment: String {
        comment ?? remark?.text ?? headline ?? ""
    }
}

// MARK: - Progress Trend Chart

private struct ProgressTrendChart: View {
    let trendData: [String: [InsightReportTrendPoint]]?

    private var data: [FatMetric] {
        let reportData = (trendData ?? [:]).flatMap { key, points in
            points.map { FatMetric(date: $0.date, value: $0.value, metric: key.displayTrendLabel) }
        }

        return reportData.sorted {
            $0.date == $1.date ? $0.metric < $1.metric : $0.date < $1.date
        }
    }

    var body: some View {
        // The chart's summary footer already legends every series; a second
        // legend above the chart would only repeat it.
        FormaTimeSeriesChart(
            points: data.map {
                FormaChartPoint(
                    date: $0.date,
                    value: $0.value,
                    metric: $0.metric,
                    color: colorForMetric($0.metric)
                )
            }
        )
    }

    private func colorForMetric(_ metric: String) -> Color {
        let lower = metric.lowercased()
        return FormaChartMetric.infer(from: lower).color
    }
}

private struct FatMetric: Identifiable {
    let date: Date
    let value: Double
    let metric: String

    var id: String {
        "\(metric)|\(date.timeIntervalSinceReferenceDate)"
    }
}

private extension BodyType {
    /// Best-matching bundled illustration for the reported body type.
    var imageName: String {
        switch self {
        case .normal:
            return "body-normal"
        default:
            return "body"
        }
    }
}

#Preview {
    InsightsTab(reportStore: MetricsReportStore())
        .padding(.vertical, 20)
        .background(Color.appBackground)
}
