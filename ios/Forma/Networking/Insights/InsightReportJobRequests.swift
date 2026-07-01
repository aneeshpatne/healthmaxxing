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
        self.path = "client/profiles/\(profileId.uuidString)/insights/jobs/active"
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
        self.path = "client/profiles/\(profileId.uuidString)/insights/jobs/\(jobId)/wait"
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
        self.path = "client/profiles/\(profileId.uuidString)/insights/report-ids/latest"
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
        self.path = "client/profiles/\(profileId.uuidString)/insights/\(insightId)"
    }
}

struct InsightReportJobsResponse: Decodable {
    let ok: Bool
    let profileId: UUID
    let jobs: [InsightReportJob]?
    let reports: [InsightReportJob]?
}

struct InsightReportJob: Decodable, Identifiable, Equatable {
    var id: UUID { jobId }

    let jobId: UUID
    let reportId: UUID
    let profileId: UUID
    let generationStatus: String
    let generationError: String?
    let createdAt: String
    let updatedAt: String
    let hasData: Bool
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

struct InsightReport: Decodable, Equatable {
    let reportId: UUID
    let profileId: UUID
    let generationStatus: String
    let generationError: String?
    let createdAt: String
    let updatedAt: String
    let data: JSONValue?
}
