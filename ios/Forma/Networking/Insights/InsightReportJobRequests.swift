//
//  InsightReportJobRequests.swift
//  Forma
//
//  Created by Codex on 30/06/26.
//

import Foundation

struct GetActiveInsightJobsRequest: APIRequest {
    typealias Response = InsightReportJobsResponse

    let path: String
    let method: HTTPMethod = .get
    let headers: [String: String] = [:]
    let queryItems: [URLQueryItem] = []
    let body: (any Encodable)? = nil
    let requiresAuth = true

    init(profileId: UUID) {
        self.path = "client/profiles/\(profileId.uuidString.lowercased())/insights/jobs/active"
    }
}

struct WaitForInsightJobRequest: APIRequest {
    typealias Response = WaitForInsightJobResponse

    let path: String
    let method: HTTPMethod = .get
    let headers: [String: String] = [:]
    let queryItems: [URLQueryItem]
    let body: (any Encodable)? = nil
    let requiresAuth = true

    init(profileId: UUID, jobId: UUID, timeoutMs: Int = 25_000) {
        self.path = "client/profiles/\(profileId.uuidString.lowercased())/insights/jobs/\(jobId.uuidString.lowercased())/wait"
        self.queryItems = [
            URLQueryItem(name: "timeoutMs", value: String(min(max(timeoutMs, 0), 30_000)))
        ]
    }
}

struct GetLatestInsightReportIdsRequest: APIRequest {
    typealias Response = InsightReportJobsResponse

    let path: String
    let method: HTTPMethod = .get
    let headers: [String: String] = [:]
    let queryItems: [URLQueryItem]
    let body: (any Encodable)? = nil
    let requiresAuth = true

    init(profileId: UUID, limit: Int = 5) {
        self.path = "client/profiles/\(profileId.uuidString.lowercased())/insights/report-ids/latest"
        self.queryItems = [
            URLQueryItem(name: "limit", value: String(min(max(limit, 1), 20)))
        ]
    }
}

struct GetInsightReportRequest: APIRequest {
    typealias Response = GetInsightReportResponse

    let path: String
    let method: HTTPMethod = .get
    let headers: [String: String] = [:]
    let queryItems: [URLQueryItem] = []
    let body: (any Encodable)? = nil
    let requiresAuth = true

    init(profileId: UUID, insightId: UUID) {
        self.path = "client/profiles/\(profileId.uuidString.lowercased())/insights/\(insightId.uuidString.lowercased())"
    }
}

struct InsightReportJobsResponse: Decodable {
    let ok: Bool
    let profileId: UUID
    let jobs: [InsightReportJob]?
    let reports: [InsightReportJob]?
}

/// Job / report list row from insights endpoints.
/// `jobId` is present on active jobs; latest/completed rows may only carry `reportId`.
struct InsightReportJob: Decodable, Identifiable, Equatable {
    var id: UUID { jobId ?? reportId }

    /// Polling id when present (active jobs). Falls back to `reportId` for completed rows.
    let jobId: UUID?
    let reportId: UUID
    let profileId: UUID
    let generationStatus: String
    let generationError: String?
    let createdAt: String
    let updatedAt: String
    let hasData: Bool

    /// Prefer real job id; completed list rows often only expose report id.
    var pollId: UUID { jobId ?? reportId }

    init(
        jobId: UUID?,
        reportId: UUID,
        profileId: UUID,
        generationStatus: String,
        generationError: String?,
        createdAt: String,
        updatedAt: String,
        hasData: Bool
    ) {
        self.jobId = jobId
        self.reportId = reportId
        self.profileId = profileId
        self.generationStatus = generationStatus
        self.generationError = generationError
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.hasData = hasData
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let reportId = try container.decode(UUID.self, forKey: .reportId)
        self.reportId = reportId
        self.jobId = try container.decodeIfPresent(UUID.self, forKey: .jobId)
        self.profileId = try container.decode(UUID.self, forKey: .profileId)
        self.generationStatus = try container.decode(String.self, forKey: .generationStatus)
        self.generationError = try container.decodeIfPresent(String.self, forKey: .generationError)
        self.createdAt = try container.decode(String.self, forKey: .createdAt)
        self.updatedAt = try container.decode(String.self, forKey: .updatedAt)
        self.hasData = try container.decodeIfPresent(Bool.self, forKey: .hasData) ?? false
    }

    private enum CodingKeys: String, CodingKey {
        case jobId, reportId, profileId, generationStatus, generationError, createdAt, updatedAt, hasData
    }
}

struct WaitForInsightJobResponse: Decodable, Equatable {
    let ok: Bool
    let profileId: UUID?
    let jobId: UUID?
    let reportId: UUID?
    let generationStatus: String?
    let generationError: String?
    let report: InsightReport?
    let error: String?
}

struct GetInsightReportResponse: Decodable, Equatable {
    let ok: Bool
    let report: InsightReport
}

struct InsightReport: Codable, Equatable {
    let reportId: UUID
    let profileId: UUID
    let generationStatus: String
    let generationError: String?
    let createdAt: String
    let updatedAt: String
    let data: JSONValue?
}
