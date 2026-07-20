//
//  MetricsReportStore.swift
//  Forma
//
//  Created by Codex on 01/07/26.
//

import Combine
import Foundation

@MainActor
final class MetricsReportStore: ObservableObject {
    @Published private(set) var completedReport: InsightReport?
    @Published private(set) var activeJob: InsightReportJob?
    @Published private(set) var latestReport: InsightReportJob?
    @Published private(set) var isLoading = false
    @Published private(set) var isWaitingForReport = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var statusMessage = "Checking for the latest report."

    private let apiClient = APIClient()
    private var cachedProfileId: UUID?
    private var pollTask: Task<Void, Never>?

    var payload: InsightReportPayload? {
        InsightReportPayload(data: completedReport?.data)
    }

    func loadLatestReport() async {
        await loadAndPollReport()
    }

    func loadAndPollReport() async {
        await loadAndPollReport(ignoringCache: false)
    }

    func refreshReport() async {
        await loadAndPollReport(ignoringCache: true)
    }

    /// Starts the loading flow from the job returned by ingest.
    /// The server job id is the source of truth for this report generation.
    func reportQueued(for profileId: UUID, jobId: UUID) {
        guard PrimaryProfileStore.primaryProfileId == profileId else { return }

        pollTask?.cancel()
        activeJob = nil
        isWaitingForReport = true
        errorMessage = nil
        statusMessage = "Report queued."
        isLoading = true

        pollTask = Task { [weak self] in
            guard let self else { return }

            await self.pollReport(profileId: profileId, jobId: jobId)

            if !Task.isCancelled {
                self.isLoading = false
            }

            self.pollTask = nil
        }
    }

    private func loadAndPollReport(ignoringCache _: Bool) async {
        guard let profileId = PrimaryProfileStore.primaryProfileId else {
            errorMessage = "Create or select a primary profile to load reports."
            return
        }

        if cachedProfileId != profileId {
            clearCachedSnapshot()
            restoreCachedReport(for: profileId)
        }

        guard !isLoading else { return }

        isLoading = true
        activeJob = nil
        isWaitingForReport = false
        errorMessage = nil
        statusMessage = "Checking for the latest report."

        defer {
            isLoading = false
        }

        do {
            let activeResponse = try await apiClient.send(GetActiveInsightJobsRequest(profileId: profileId))
            let serverJobs = activeResponse.jobs ?? []
            let jobIdToPoll = serverJobs.sorted { $0.createdAt > $1.createdAt }.first?.pollId

            activeJob = serverJobs.first(where: { $0.pollId == jobIdToPoll }) ?? serverJobs.first
            isWaitingForReport = jobIdToPoll != nil

            if let jobIdToPoll {
                statusMessage = "Waiting for report generation."
                await pollReport(profileId: profileId, jobId: jobIdToPoll)
                return
            }

            let latestResponse = try await apiClient.send(GetLatestInsightReportIdsRequest(profileId: profileId))
            latestReport = latestResponse.reports?.first
            guard let latestReport else {
                completedReport = nil
                statusMessage = "No completed reports yet."
                cacheSnapshot(for: profileId)
                return
            }

            statusMessage = "Loading report details."
            let reportResponse = try await apiClient.send(GetInsightReportRequest(profileId: profileId, insightId: latestReport.reportId))
            completedReport = reportResponse.report
            statusMessage = "Latest report ready."
            cacheSnapshot(for: profileId)
        } catch APIError.missingAuthToken {
            errorMessage = "Missing auth token."
        } catch APIError.serverError(let statusCode, _) {
            errorMessage = "Server returned \(statusCode)."
        } catch {
            if (error as? URLError)?.code == .cancelled || error is CancellationError {
                return
            }

            errorMessage = "Failed to load report."
        }
    }

    private func pollReport(profileId: UUID, jobId: UUID) async {
        while !Task.isCancelled {
            let response: WaitForInsightJobResponse

            do {
                response = try await apiClient.send(WaitForInsightJobRequest(profileId: profileId, jobId: jobId))
            } catch {
                if (error as? URLError)?.code == .cancelled || error is CancellationError {
                    return
                }

                statusMessage = "Report status unavailable."
                isWaitingForReport = false
                errorMessage = "Failed to update report status."
                return
            }

            if response.ok == false {
                InsightReportJobStore.remove(jobId, for: profileId)
                activeJob = nil
                isWaitingForReport = false
                errorMessage = response.error ?? "Report job does not exist."
                return
            }

            guard let generationStatus = response.generationStatus else {
                isWaitingForReport = false
                errorMessage = "Report status is unavailable."
                return
            }

            switch generationStatus {
            case "completed":
                InsightReportJobStore.remove(jobId, for: profileId)
                activeJob = nil
                isWaitingForReport = false
                completedReport = response.report
                statusMessage = "Report completed."
                errorMessage = nil
                cacheSnapshot(for: profileId)
                return
            case "failed":
                InsightReportJobStore.remove(jobId, for: profileId)
                activeJob = nil
                isWaitingForReport = false
                errorMessage = response.generationError ?? "Report generation failed."
                return
            case "pending", "queued", "running":
                isWaitingForReport = true
                statusMessage = "Report \(generationStatus)."
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
                isWaitingForReport = false
                statusMessage = "Report \(generationStatus)."
                return
            }
        }
    }

    private func cacheSnapshot(for profileId: UUID) {
        cachedProfileId = profileId

        if let completedReport {
            InsightReportCacheStore.save(completedReport, for: profileId)
        } else {
            InsightReportCacheStore.remove(for: profileId)
        }
    }

    private func restoreCachedReport(for profileId: UUID) {
        cachedProfileId = profileId
        guard let report = InsightReportCacheStore.load(for: profileId) else { return }

        completedReport = report
        statusMessage = "Latest report ready."
    }

    private func clearCachedSnapshot() {
        cachedProfileId = nil
        completedReport = nil
        activeJob = nil
        isWaitingForReport = false
        latestReport = nil
        errorMessage = nil
        statusMessage = "Checking for the latest report."
    }
}

private enum InsightReportCacheStore {
    private static let directoryName = "InsightReports"

    static func load(for profileId: UUID) -> InsightReport? {
        guard let data = try? Data(contentsOf: fileURL(for: profileId)) else { return nil }
        return try? JSONDecoder().decode(InsightReport.self, from: data)
    }

    static func save(_ report: InsightReport, for profileId: UUID) {
        guard let data = try? JSONEncoder().encode(report) else { return }
        let fileURL = fileURL(for: profileId)

        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try data.write(to: fileURL, options: [.atomic, .completeFileProtection])
        } catch {
            return
        }
    }

    static func remove(for profileId: UUID) {
        try? FileManager.default.removeItem(at: fileURL(for: profileId))
    }

    private static func fileURL(for profileId: UUID) -> URL {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]

        return applicationSupportURL
            .appendingPathComponent(directoryName, isDirectory: true)
            .appendingPathComponent("\(profileId.uuidString).json", isDirectory: false)
    }
}
