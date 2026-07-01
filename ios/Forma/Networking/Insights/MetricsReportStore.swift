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
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let apiClient = APIClient()

    var payload: InsightReportPayload? {
        InsightReportPayload(data: completedReport?.data)
    }

    func loadLatestReport() async {
        guard !isLoading else { return }
        guard let profileId = PrimaryProfileStore.primaryProfileId else {
            errorMessage = "Create or select a primary profile to load reports."
            return
        }

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        do {
            let latestResponse = try await apiClient.send(GetLatestInsightReportIdsRequest(profileId: profileId))
            guard let latestReport = latestResponse.reports?.first else {
                completedReport = nil
                return
            }

            let reportResponse = try await apiClient.send(GetInsightReportRequest(profileId: profileId, insightId: latestReport.reportId))
            completedReport = reportResponse.report
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
}
