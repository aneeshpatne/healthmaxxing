import SwiftUI
import Charts

struct InsightsTab: View {
    @State private var activeJob: InsightReportJob?
    @State private var latestReport: InsightReportJob?
    @State private var completedReport: InsightReport?
    @State private var reportStatus: String?
    @State private var reportError: String?
    @State private var isLoadingReports = false

    private let apiClient = APIClient()
    private var reportPayload: InsightReportPayload? {
        InsightReportPayload(data: completedReport?.data)
    }
    private var effortScore: Double? {
        reportPayload?.effortScore?.score.map { min(100, max(0, $0)) }
    }

    var body: some View {
        Group {
            if completedReport == nil && isLoadingReports {
                MetricsReportStatusScreen(
                    title: "Generating report",
                    message: reportStatus ?? "Checking report status.",
                    isLoading: true
                )
            } else if reportPayload == nil {
                InsightReportStatusCard(
                    isLoading: isLoadingReports,
                    status: reportStatus,
                    errorMessage: reportError,
                    activeJob: activeJob,
                    latestReport: latestReport,
                    completedReport: completedReport,
                    refreshAction: {
                        Task {
                            await loadAndPollReports()
                        }
                    }
                )
                .insightsCard()
                .padding(.top, 4)
                .padding(.bottom, 24)
            } else {
                VStack(spacing: 20) {
                InsightReportStatusCard(
                    isLoading: isLoadingReports,
                    status: reportStatus,
                    errorMessage: reportError,
                    activeJob: activeJob,
                    latestReport: latestReport,
                    completedReport: completedReport,
                    refreshAction: {
                        Task {
                            await loadAndPollReports()
                        }
                    }
                )
                .insightsCard()

                if let overview = reportPayload?.overview {
                // MARK: - Weekly Summary Card
                VStack(alignment: .leading, spacing: 18) {
                    FormaCardHeader(overview.title ?? overview.displayTitle)

                    // Insight text
                    Text(overview.headline ?? overview.displayComment)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Subtle separator
                    Rectangle()
                        .fill(Color.appSeparator)
                        .frame(height: 1)

                    // Premium insight row
                    FormaCallout(
                        text: overview.remark?.text ?? overview.displayComment,
                        systemImage: overview.remark?.marker?.iconName ?? "flame.fill",
                        tint: overview.remark?.marker?.color ?? .orange
                    )
                }
                .insightsCard()
                }

                if let foundation = reportPayload?.foundation {
                // MARK: - Strong Base Card
                VStack(alignment: .leading, spacing: 18) {
                    FormaCardHeader(foundation.title ?? foundation.displayTitle)

                    // Headline
                    Text(foundation.headline ?? foundation.displayComment)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body
                    Text(foundation.comment ?? foundation.remark?.text ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Subtle separator
                    Rectangle()
                        .fill(Color.appSeparator)
                        .frame(height: 1)

                    // Insight row
                    FormaCallout(
                        text: foundation.remark?.text ?? foundation.displayComment,
                        systemImage: foundation.remark?.marker?.iconName ?? "checkmark.circle.fill",
                        tint: foundation.remark?.marker?.color ?? .green
                    )
                }
                .insightsCard()
                }

                if let progress = reportPayload?.progress {
                // MARK: - Progress Trend Card
                VStack(alignment: .leading, spacing: 18) {
                    FormaCardHeader(progress.title ?? progress.displayTitle)

                    // Headline
                    Text(progress.headline ?? progress.displayComment)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body
                    Text(progress.comment ?? progress.remark?.text ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Chart card
                    ProgressTrendChart(trendData: progress.trendData)

                    // Subtle separator
                    Rectangle()
                        .fill(Color.appSeparator)
                        .frame(height: 1)

                    // Insight row
                    FormaCallout(
                        text: progress.remark?.text ?? progress.displayComment,
                        systemImage: progress.remark?.marker?.iconName ?? "sparkle",
                        tint: progress.remark?.marker?.color ?? .green
                    )
                }
                .insightsCard()
                }

                if let lever = reportPayload?.lever {
                // MARK: - Waist Focus Card
                VStack(alignment: .leading, spacing: 18) {
                    FormaCardHeader(lever.title ?? lever.displayTitle)

                    // Headline
                    Text(lever.headline ?? lever.displayComment)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body
                    Text(lever.comment ?? lever.remark?.text ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Subtle separator
                    Rectangle()
                        .fill(Color.appSeparator)
                        .frame(height: 1)

                    // Insight row
                    FormaCallout(
                        text: lever.remark?.text ?? lever.displayComment,
                        systemImage: lever.remark?.marker?.iconName ?? "arrow.up.forward.circle.fill",
                        tint: lever.remark?.marker?.color ?? .green
                    )
                }
                .insightsCard()
                }

                if let physiqueArchetype = reportPayload?.physiqueArchetype {
                // MARK: - Broad Frame Card
                VStack(alignment: .leading, spacing: 18) {
                    FormaCardHeader(physiqueArchetype.title ?? "Physique")

                    // Headline
                    Text(physiqueArchetype.headline ?? physiqueArchetype.comment ?? "")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body
                    Text(physiqueArchetype.comment ?? "")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body-shape illustration
                    Image("body-normal")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .background(Color.appTertiaryBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.appSeparator, lineWidth: 0.5)
                        }
                        .accessibilityLabel("Broad body frame illustration")

                    // Subtle separator
                    Rectangle()
                        .fill(Color.appSeparator)
                        .frame(height: 1)

                    // Insight row
                    FormaCallout(
                        text: physiqueArchetype.bodyType.map { "Body type: \($0.capitalized)" } ?? physiqueArchetype.comment ?? "",
                        systemImage: "dumbbell.fill",
                        tint: .blue
                    )
                }
                .insightsCard()
                }

                if let effortScore, let effortSection = reportPayload?.effortScore {
                // MARK: - Effort Score Card
                VStack(alignment: .leading, spacing: 18) {
                    FormaCardHeader(effortSection.title ?? "Effort Score") {
                        Text(String(format: "%.0f", effortScore))
                            .font(.subheadline.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(.green)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.green.opacity(0.12), in: Capsule())
                    }

                    // Low-to-high score range and current position
                    GeometryReader { geometry in
                        let markerRadius: CGFloat = 8
                        let markerX = min(
                            geometry.size.width - markerRadius,
                            max(markerRadius, geometry.size.width * CGFloat(effortScore / 100))
                        )

                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.red, .orange, .yellow, .green],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(height: 8)

                            Circle()
                                .fill(Color.appSecondaryBackground)
                                .frame(width: markerRadius * 2, height: markerRadius * 2)
                                .overlay {
                                    Circle()
                                        .stroke(.green, lineWidth: 3)
                                }
                                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
                                .position(x: markerX, y: markerRadius)
                        }
                    }
                    .frame(height: 16)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("Effort score")
                    .accessibilityValue("\(String(format: "%.0f", effortScore)) out of 100")

                    // Subtle separator
                    Rectangle()
                        .fill(Color.appSeparator)
                        .frame(height: 1)

                    // Contextual insight
                    FormaCallout(
                        text: effortSection.comment ?? effortSection.remark?.text ?? "",
                        systemImage: effortSection.remark?.marker?.iconName ?? "chart.line.downtrend.xyaxis",
                        tint: effortSection.remark?.marker?.color ?? .green
                    )
                }
                .insightsCard()
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
            }
        }
        .padding(.horizontal, FormaSpacing.screenGutter)
        .task {
            await loadAndPollReports()
        }
    }

    @MainActor
    private func loadAndPollReports() async {
        guard !isLoadingReports else { return }

        guard let profileId = PrimaryProfileStore.primaryProfileId else {
            reportError = "Create or select a primary profile to load insight reports."
            return
        }

        isLoadingReports = true
        reportError = nil
        reportStatus = "Checking reports"

        defer {
            isLoadingReports = false
        }

        do {
            let activeResponse = try await apiClient.send(GetActiveInsightJobsRequest(profileId: profileId))
            let serverJobs = activeResponse.jobs ?? []
            let storedJobIds = InsightReportJobStore.jobIds(for: profileId)
            let jobIdToPoll = serverJobs.sorted { $0.createdAt > $1.createdAt }.first?.jobId ?? storedJobIds.first

            activeJob = serverJobs.first(where: { $0.jobId == jobIdToPoll }) ?? serverJobs.first

            if let jobIdToPoll {
                await pollReport(profileId: profileId, jobId: jobIdToPoll)
                return
            }

            let latestResponse = try await apiClient.send(GetLatestInsightReportIdsRequest(profileId: profileId))
            latestReport = latestResponse.reports?.first
            if let latestReport {
                let reportResponse = try await apiClient.send(GetInsightReportRequest(profileId: profileId, insightId: latestReport.reportId))
                completedReport = reportResponse.report
            }
            reportStatus = latestReport == nil ? "No completed reports yet" : "Latest report ready"
        } catch APIError.missingAuthToken {
            reportStatus = nil
            reportError = "Missing auth token."
        } catch APIError.serverError(let statusCode, _) {
            reportStatus = nil
            reportError = "Server returned \(statusCode)."
        } catch {
            if (error as? URLError)?.code == .cancelled || error is CancellationError {
                return
            }

            reportStatus = nil
            reportError = "Failed to load insight reports."
        }
    }

    @MainActor
    private func pollReport(profileId: UUID, jobId: UUID) async {
        while !Task.isCancelled {
            let response: WaitForInsightJobResponse

            do {
                response = try await apiClient.send(WaitForInsightJobRequest(profileId: profileId, jobId: jobId))
            } catch {
                if (error as? URLError)?.code == .cancelled || error is CancellationError {
                    return
                }

                reportStatus = nil
                reportError = "Failed to update report status."
                return
            }

            if response.ok == false {
                InsightReportJobStore.remove(jobId, for: profileId)
                activeJob = nil
                reportStatus = nil
                reportError = response.error ?? "Report job does not exist."
                return
            }

            guard let generationStatus = response.generationStatus else {
                reportStatus = nil
                reportError = "Report status is unavailable."
                return
            }

            switch generationStatus {
            case "completed":
                InsightReportJobStore.remove(jobId, for: profileId)
                activeJob = nil
                completedReport = response.report
                reportStatus = "Report completed"
                reportError = nil
                return
            case "failed":
                InsightReportJobStore.remove(jobId, for: profileId)
                activeJob = nil
                reportStatus = nil
                reportError = response.generationError ?? "Report generation failed."
                return
            case "pending", "queued", "running":
                reportStatus = "Report \(generationStatus)"
                activeJob = response.report.map {
                    InsightReportJob(
                        jobId: jobId,
                        reportId: $0.reportId,
                        profileId: $0.profileId,
                        generationStatus: generationStatus,
                        generationError: $0.generationError,
                        createdAt: $0.createdAt,
                        updatedAt: $0.updatedAt,
                        hasData: $0.data != nil
                    )
                } ?? activeJob
            default:
                reportStatus = "Report \(generationStatus)"
                return
            }
        }
    }
}

private struct InsightReportStatusCard: View {
    let isLoading: Bool
    let status: String?
    let errorMessage: String?
    let activeJob: InsightReportJob?
    let latestReport: InsightReportJob?
    let completedReport: InsightReport?
    let refreshAction: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FormaCardHeader("AI Report") {
                Button(action: refreshAction) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(isLoading)
                .accessibilityLabel("Refresh report")
            }

            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                }

                Text(primaryText)
                    .font(.body.weight(.medium))
                    .foregroundStyle(errorMessage == nil ? Color.primary : Color.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let secondaryText {
                Text(secondaryText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if completedReport == nil, activeJob == nil, latestReport == nil, errorMessage == nil {
                Text("Record a measurement in Record to generate your first report.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var primaryText: String {
        if let errorMessage {
            return errorMessage
        }

        if completedReport != nil {
            return "Latest report ready"
        }

        if let status {
            return status
        }

        return "Checking reports"
    }

    private var secondaryText: String? {
        if let activeJob {
            return "Report generation in progress · \(activeJob.generationStatus.capitalized)"
        }

        if let completedReport {
            return "Updated \(formattedDate(completedReport.updatedAt))"
        }

        if let latestReport {
            return "Updated \(formattedDate(latestReport.updatedAt))"
        }

        return nil
    }

    private func formattedDate(_ value: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: value) else {
            return "recently"
        }

        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }

}

// MARK: - Insights Card Modifier

private struct InsightsCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .formaSurface(.card, padding: FormaSpacing.cardInset)
    }
}

private extension View {
    func insightsCard() -> some View {
        modifier(InsightsCardModifier())
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

    private var uniqueMetrics: [String] {
        var seen = Set<String>()
        var result = [String]()
        for item in data {
            if !seen.contains(item.metric) {
                seen.insert(item.metric)
                result.append(item.metric)
            }
        }
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if uniqueMetrics.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: FormaSpacing.sm) {
                        ForEach(uniqueMetrics, id: \.self) { metric in
                            Label {
                                Text(metric).font(.caption2.weight(.medium))
                            } icon: {
                                Circle().fill(colorForMetric(metric)).frame(width: 6, height: 6)
                            }
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }

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

#Preview {
    InsightsTab()
        .padding(.vertical, 20)
        .background(Color.appBackground)
}
