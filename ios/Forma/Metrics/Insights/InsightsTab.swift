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
    private var effortScore: Double {
        min(100, max(0, reportPayload?.effortScore?.score ?? 82))
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
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

                // MARK: - Weekly Summary Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 26, height: 26)
                            .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(reportPayload?.overview?.title ?? "Weekly Summary")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.0)

                        Spacer()

                        Text("Jun 16 – 22")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(.fill.tertiary, in: Capsule())
                    }

                    // Insight text
                    Text(reportPayload?.overview?.headline ?? "Foundation is strong — body fat trending down while lean mass holds steady.")
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
                        Image(systemName: "flame.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.orange)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.orange.opacity(0.1))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(reportPayload?.overview?.remark?.marker?.displayRemarkMarker ?? "Body Fat")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)

                            Text(reportPayload?.overview?.remark?.text ?? "Down 0.4% this week")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        // Trend badge
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.right")
                                .font(.system(size: 10, weight: .bold))
                            Text("−0.4%")
                                .font(.caption.weight(.bold))
                                .monospacedDigit()
                        }
                        .foregroundStyle(.green)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.green.opacity(0.1), in: Capsule())
                    }
                }
                .insightsCard()

                // MARK: - Strong Base Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 26, height: 26)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(reportPayload?.foundation?.title ?? "Strong Base")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.0)

                        Spacer()
                    }

                    // Headline
                    Text(reportPayload?.foundation?.headline ?? "54.6 kg of lean mass gives you a strong foundation")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body
                    Text(reportPayload?.foundation?.comment ?? "At 172 cm, your current muscle base supports a strong, athletic look as you continue leaning out.")
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
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.green.opacity(0.1))
                            )

                        Text(reportPayload?.foundation?.remark?.text ?? "Keep protein intake steady and stay consistent with strength training to maintain this muscle.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .insightsCard()

                // MARK: - Progress Trend Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 26, height: 26)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(reportPayload?.progress?.title ?? "Progress Trend")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.0)

                        Spacer()
                    }

                    // Headline
                    Text(reportPayload?.progress?.headline ?? "Body fat is moving down across every view")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body
                    Text(reportPayload?.progress?.comment ?? "Subcutaneous fat is down 0.89 kg over the last 30 days, while overall fat markers continue trending lower.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Chart card
                    ProgressTrendChart(trendData: reportPayload?.progress?.trendData)

                    // Subtle separator
                    Rectangle()
                        .fill(Color.appSeparator)
                        .frame(height: 1)

                    // Insight row
                    HStack(spacing: 14) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Color.appSecondaryBackground)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.green.opacity(0.85))
                            )

                        Text(reportPayload?.progress?.remark?.text ?? "Steady progress like this is a strong sign your current rhythm is working. Keep the pace consistent.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .insightsCard()

                // MARK: - Waist Focus Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "ruler.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 26, height: 26)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(reportPayload?.lever?.title ?? "Waist Focus")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.0)

                        Spacer()
                    }

                    // Headline
                    Text(reportPayload?.lever?.headline ?? "A smaller waist will make your upper body stand out")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body
                    Text(reportPayload?.lever?.comment ?? "With a 90 cm waist, 103 cm shoulders, and 106 cm chest, you already have the structure for a strong V-taper. Reducing your waist will make that shape more pronounced.")
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
                        Image(systemName: "arrow.up.forward.circle.fill")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.green.opacity(0.1))
                            )

                        Text(reportPayload?.lever?.remark?.text ?? "Even a modest reduction in waist size can significantly improve your shoulder-to-waist ratio.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .insightsCard()

                // MARK: - Broad Frame Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header
                    HStack(spacing: 8) {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.blue)
                            .frame(width: 26, height: 26)
                            .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(reportPayload?.physiqueArchetype?.title ?? "Broad Frame")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.0)

                        Spacer()
                    }

                    // Headline
                    Text(reportPayload?.physiqueArchetype?.headline ?? "Strong Foundation Frame")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.primary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)

                    // Body
                    Text(reportPayload?.physiqueArchetype?.comment ?? "Your frame is broad and solid, giving you a strong base to build on. As your waist leans out, your natural shape will become even more defined.")
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

                        Text(reportPayload?.physiqueArchetype?.bodyType.map { "Body type: \($0.capitalized)" } ?? "Keep developing your shoulders, back, and upper chest. These are your strongest visual assets and will make the biggest impact as you lean out.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .insightsCard()

                // MARK: - Effort Score Card
                VStack(alignment: .leading, spacing: 18) {
                    // Header and primary score
                    HStack(spacing: 8) {
                        Image(systemName: "speedometer")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 26, height: 26)
                            .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 7, style: .continuous))

                        Text(reportPayload?.effortScore?.title ?? "Effort Score")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(1.0)

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
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.green)
                            .frame(width: 36, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(.green.opacity(0.1))
                            )

                        Text(reportPayload?.effortScore?.comment ?? reportPayload?.effortScore?.remark?.text ?? "Your body fat is trending down while muscle remains stable, which is driving a strong effort score.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)

                        Spacer()
                    }
                }
                .insightsCard()
            }
            .padding(.top, 4)
            .padding(.bottom, 24)
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
                    .tracking(1.0)

                Spacer()

                Button(action: refreshAction) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption.weight(.bold))
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .disabled(isLoading)
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
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
        }
    }

    private var primaryText: String {
        if let errorMessage {
            return errorMessage
        }

        if let status {
            return status
        }

        return "Checking reports"
    }

    private var secondaryText: String? {
        if let activeJob {
            return "Job \(activeJob.jobId)"
        }

        if let completedReport {
            return "Report \(completedReport.reportId)"
        }

        if let latestReport {
            return "Report \(latestReport.reportId)"
        }

        return nil
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
    func body(content: Content) -> some View {
        content
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

private extension View {
    func insightsCard() -> some View {
        modifier(InsightsCardModifier())
    }
}

// MARK: - Progress Trend Chart

private struct ProgressTrendChart: View {
    let trendData: [String: [InsightReportTrendPoint]]?

    private var data: [FatMetric] {
        let reportData = (trendData ?? [:]).flatMap { key, points in
            points.map { FatMetric(date: $0.shortDate, value: $0.value, metric: key.displayTrendLabel) }
        }

        if !reportData.isEmpty {
            return reportData
        }

        return [
        // Body Fat
        FatMetric(date: "May 24", value: 18.5, metric: "Body Fat"),
        FatMetric(date: "May 31", value: 18.2, metric: "Body Fat"),
        FatMetric(date: "Jun 7", value: 18.0, metric: "Body Fat"),
        FatMetric(date: "Jun 14", value: 17.9, metric: "Body Fat"),
        FatMetric(date: "Jun 22", value: 17.8, metric: "Body Fat"),

        // Subcutaneous Fat
        FatMetric(date: "May 24", value: 14.2, metric: "Subcutaneous Fat"),
        FatMetric(date: "May 31", value: 14.0, metric: "Subcutaneous Fat"),
        FatMetric(date: "Jun 7", value: 13.7, metric: "Subcutaneous Fat"),
        FatMetric(date: "Jun 14", value: 13.5, metric: "Subcutaneous Fat"),
        FatMetric(date: "Jun 22", value: 13.4, metric: "Subcutaneous Fat"),

        // Visceral Fat
        FatMetric(date: "May 24", value: 8.5, metric: "Visceral Fat"),
        FatMetric(date: "May 31", value: 8.3, metric: "Visceral Fat"),
        FatMetric(date: "Jun 7", value: 8.1, metric: "Visceral Fat"),
        FatMetric(date: "Jun 14", value: 7.9, metric: "Visceral Fat"),
            FatMetric(date: "Jun 22", value: 7.8, metric: "Visceral Fat")
        ]
    }

    private let metrics: [(String, Color)] = [
        ("Body Fat", .green),
        ("Subcutaneous Fat", Color(red: 0.35, green: 0.55, blue: 0.95)),
        ("Visceral Fat", Color(red: 0.95, green: 0.65, blue: 0.25))
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Legend
            HStack(spacing: 14) {
                ForEach(metrics, id: \.0) { metric, color in
                    HStack(spacing: 5) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(color)
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
                    y: .value("Value", item.value)
                )
                .foregroundStyle(colorForMetric(item.metric))
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .interpolationMethod(.catmullRom)
                .symbol {
                    Circle()
                        .fill(colorForMetric(item.metric))
                        .frame(width: 4, height: 4)
                        .shadow(color: colorForMetric(item.metric).opacity(0.3), radius: 2, x: 0, y: 1)
                }
            }
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
            .chartXAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(height: 160)
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
        switch metric {
        case "Body Fat": return .green
        case "Subcutaneous Fat": return Color(red: 0.35, green: 0.55, blue: 0.95)
        case "Visceral Fat": return Color(red: 0.95, green: 0.65, blue: 0.25)
        default: return .secondary
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
