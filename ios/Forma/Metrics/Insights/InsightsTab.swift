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
        ScrollView(showsIndicators: false) {
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
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 26, height: 26)
                            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(overview.title ?? overview.displayTitle)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Spacer()

                    }

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
                    HStack(spacing: 14) {
                        let marker = overview.remark?.marker
                        Image(systemName: marker?.iconName ?? "flame.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(marker?.color ?? .orange)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill((marker?.color ?? .orange).opacity(0.1))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(marker?.displayRemarkMarker ?? "Insight")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text(overview.remark?.text ?? overview.displayComment)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Trend badge
                    }
                }
                .insightsCard()
                }

                if let foundation = reportPayload?.foundation {
                // MARK: - Strong Base Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 26, height: 26)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(foundation.title ?? foundation.displayTitle)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Spacer()
                    }

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
                    HStack(spacing: 14) {
                        let marker = foundation.remark?.marker
                        Image(systemName: marker?.iconName ?? "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(marker?.color ?? .green)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill((marker?.color ?? .green).opacity(0.1))
                            )

                        Text(foundation.remark?.text ?? foundation.displayComment)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .insightsCard()
                }

                if let progress = reportPayload?.progress {
                // MARK: - Progress Trend Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 26, height: 26)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(progress.title ?? progress.displayTitle)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Spacer()
                    }

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
                    HStack(spacing: 14) {
                        let marker = progress.remark?.marker
                        Image(systemName: marker?.iconName ?? "sparkle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.appSecondaryBackground)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill((marker?.color ?? .green).opacity(0.85))
                            )

                        Text(progress.remark?.text ?? progress.displayComment)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .insightsCard()
                }

                if let lever = reportPayload?.lever {
                // MARK: - Waist Focus Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "ruler.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 26, height: 26)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(lever.title ?? lever.displayTitle)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Spacer()
                    }

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
                    HStack(spacing: 14) {
                        let marker = lever.remark?.marker
                        Image(systemName: marker?.iconName ?? "arrow.up.forward.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(marker?.color ?? .green)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill((marker?.color ?? .green).opacity(0.1))
                            )

                        Text(lever.remark?.text ?? lever.displayComment)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .insightsCard()
                }

                if let physiqueArchetype = reportPayload?.physiqueArchetype {
                // MARK: - Broad Frame Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 26, height: 26)
                            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(physiqueArchetype.title ?? "Physique")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Spacer()
                    }

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
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.appSeparator, lineWidth: 0.5)
                        }
                        .accessibilityLabel("Broad body frame illustration")

                    // Subtle separator
                    Rectangle()
                        .fill(Color.appSeparator)
                        .frame(height: 1)

                    // Insight row
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.blue.opacity(0.1))
                            )

                        Text(physiqueArchetype.bodyType.map { "Body type: \($0.capitalized)" } ?? physiqueArchetype.comment ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .insightsCard()
                }

                if let effortScore, let effortSection = reportPayload?.effortScore {
                // MARK: - Effort Score Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header and primary score
                    HStack(spacing: 8) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 26, height: 26)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(effortSection.title ?? "Effort Score")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.6)

                        Spacer()

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
                    HStack(alignment: .top, spacing: 14) {
                        let marker = effortSection.remark?.marker
                        Image(systemName: marker?.iconName ?? "chart.line.downtrend.xyaxis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(marker?.color ?? .green)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill((marker?.color ?? .green).opacity(0.1))
                            )

                        Text(effortSection.comment ?? effortSection.remark?.text ?? "")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .insightsCard()
                }
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
            }
        }
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
            HStack(spacing: 10) {
                Image(systemName: iconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(iconColor)
                    .frame(width: 26, height: 26)
                    .background(iconColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                Text("AI Report")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.6)

                Spacer()

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

    private var iconName: String {
        if errorMessage != nil {
            return "exclamationmark.triangle.fill"
        }

        if isLoading || activeJob != nil {
            return "hourglass"
        }

        return "sparkles"
    }

    private var iconColor: Color {
        if errorMessage != nil {
            return .red
        }

        if isLoading || activeJob != nil {
            return .orange
        }

        return Color.accentColor
    }
}

// MARK: - Insights Card Modifier

private struct InsightsCardModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared || reduceMotion ? 1 : 0)
            .offset(y: hasAppeared || reduceMotion ? 0 : 8)
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.appSecondaryBackground)
                    .shadow(color: Color.cardShadow, radius: 12, x: 0, y: 4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.appSeparator, lineWidth: 0.5)
            )
            .padding(.horizontal, 16)
            .onAppear {
                guard !hasAppeared else { return }

                if reduceMotion {
                    hasAppeared = true
                } else {
                    withAnimation(.easeOut(duration: 0.24)) {
                        hasAppeared = true
                    }
                }
            }
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
    @State private var selectedDate: String?

    private var data: [FatMetric] {
        let reportData = (trendData ?? [:]).flatMap { key, points in
            points.map { FatMetric(date: $0.shortDate, value: $0.value, metric: key.displayTrendLabel) }
        }

        return reportData
    }

    private var yDomain: ClosedRange<Double> {
        let values = data.map { $0.value }
        guard let minVal = values.min(), let maxVal = values.max() else {
            return 0...100
        }
        if minVal == maxVal {
            return (minVal - 1.5)...(maxVal + 1.5)
        }
        return (minVal - 1.5)...(maxVal + 1.5)
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
        let latestDate = data.map { $0.date }.last
        
        VStack(alignment: .leading, spacing: 14) {
            if data.isEmpty {
                MetricsUnavailableContent(message: "Trend data is unavailable for this report.")
            } else {
            // Legend
            HStack(spacing: 14) {
                ForEach(uniqueMetrics, id: \.self) { metric in
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(colorForMetric(metric))
                            .frame(width: 10, height: 3)

                        Text(metric)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }

            // Chart — no animation, renders immediately
            Chart(data) { item in
                LineMark(
                    x: .value("Date", item.date),
                    y: .value("Value", item.value),
                    series: .value("Metric", item.metric)
                )
                .foregroundStyle(colorForMetric(item.metric))
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
                
                if let latestDate, item.date == latestDate {
                    PointMark(
                        x: .value("Date", item.date),
                        y: .value("Value", item.value)
                    )
                    .foregroundStyle(colorForMetric(item.metric))
                    .symbol {
                        Circle()
                            .fill(colorForMetric(item.metric))
                            .frame(width: 8, height: 8)
                            .overlay(Circle().stroke(Color.white, lineWidth: 2))
                            .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .chartXSelection(value: $selectedDate)
            .chartYScale(domain: yDomain)
            .chartLegend(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [3, 3]))
                        .foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 160)

            if let selectedDate {
                let selectedItems = data.filter { $0.date == selectedDate }
                if !selectedItems.isEmpty {
                    HStack(alignment: .top, spacing: 12) {
                        Text(selectedDate)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.primary)

                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(selectedItems) { item in
                                Text("\(item.metric): \(item.value, specifier: "%.1f")")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.top, 2)
                }
            }
            }
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

    private func colorForMetric(_ metric: String) -> Color {
        let lower = metric.lowercased()
        if lower.contains("body fat") || lower.contains("fat ratio") {
            return .green
        } else if lower.contains("subcutaneous") {
            return Color(red: 0.35, green: 0.55, blue: 0.95)
        } else if lower.contains("visceral") {
            return Color(red: 0.95, green: 0.65, blue: 0.25)
        } else if lower.contains("fat mass") || lower.contains("fat") {
            return .red
        } else if lower.contains("muscle") {
            return .orange
        } else if lower.contains("lean") {
            return .blue
        } else if lower.contains("bone") {
            return .gray
        } else {
            return .secondary
        }
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
