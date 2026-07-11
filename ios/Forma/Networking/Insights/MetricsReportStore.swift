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
    @Published private(set) var errorMessage: String?
    @Published private(set) var statusMessage = "Checking for the latest report."

    private let apiClient = APIClient()

    var payload: InsightReportPayload? {
        InsightReportPayload(data: completedReport?.data)
    }

    func loadLatestReport() async {
        await loadAndPollReport()
    }

    func loadAndPollReport() async {
        guard !isLoading else { return }
        guard let profileId = PrimaryProfileStore.primaryProfileId else {
            errorMessage = "Create or select a primary profile to load reports."
            return
        }

        isLoading = true
        errorMessage = nil
        statusMessage = "Checking for the latest report."

        defer {
            isLoading = false
        }

        do {
            let activeResponse = try await apiClient.send(GetActiveInsightJobsRequest(profileId: profileId))
            let serverJobs = activeResponse.jobs ?? []
            let storedJobIds = InsightReportJobStore.jobIds(for: profileId)
            let jobIdToPoll = serverJobs.sorted { $0.createdAt > $1.createdAt }.first?.jobId ?? storedJobIds.first

            activeJob = serverJobs.first(where: { $0.jobId == jobIdToPoll }) ?? serverJobs.first

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
                return
            }

            statusMessage = "Loading report details."
            let reportResponse = try await apiClient.send(GetInsightReportRequest(profileId: profileId, insightId: latestReport.reportId))
            completedReport = reportResponse.report
            statusMessage = "Latest report ready."
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
                errorMessage = "Failed to update report status."
                return
            }

            if response.ok == false {
                InsightReportJobStore.remove(jobId, for: profileId)
                activeJob = nil
                errorMessage = response.error ?? "Report job does not exist."
                return
            }

            guard let generationStatus = response.generationStatus else {
                errorMessage = "Report status is unavailable."
                return
            }

            switch generationStatus {
            case "completed":
                InsightReportJobStore.remove(jobId, for: profileId)
                activeJob = nil
                completedReport = response.report
                statusMessage = "Report completed."
                errorMessage = nil
                return
            case "failed":
                InsightReportJobStore.remove(jobId, for: profileId)
                activeJob = nil
                errorMessage = response.generationError ?? "Report generation failed."
                return
            case "pending", "queued", "running":
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
                statusMessage = "Report \(generationStatus)."
                return
            }
        }
    }
}
