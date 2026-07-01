//
//  AddMeasurementRequest.swift
//  Forma
//
//  Created by Codex on 30/06/26.
//

import Foundation

struct AddMeasurementRequest: APIRequest {
    typealias Response = AddMeasurementResponse

    let path = "ingest/add_measurement/v2"
    let method: HTTPMethod = .post
    let headers: [String: String] = [:]
    let queryItems: [URLQueryItem] = []
    let body: (any Encodable)?
    let requiresAuth = true

    init(body: AddMeasurementBody) {
        self.body = body
    }
}

struct AddMeasurementBody: Encodable {
    let profileId: UUID
    let weight: Double
    let heartbeat: Int
    let impedance: Double
}

struct AddMeasurementResponse: Decodable {
    let ok: Bool
    let id: UUID
    let jobId: UUID
    let reportId: UUID
    let reportStatus: String
    let reports: MeasurementReportIds
}

struct MeasurementReportIds: Decodable {
    let performanceReportId: UUID
    let insightReportId: UUID
    let fatReportId: UUID
    let muscleReportId: UUID
}
