//
//  UpdateClientProfileRequest.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//

import Foundation

struct UpdateClientProfileRequest: APIRequest {
    typealias Response = UpdateClientProfileResponse

    let path: String
    let method: HTTPMethod = .patch
    let headers: [String: String] = [:]
    let queryItems: [URLQueryItem] = []
    let body: (any Encodable)?
    let requiresAuth = true

    init(profileId: UUID, body: UpdateClientProfileBody) {
        // Server lowercases profileId path segments.
        self.path = "client/profiles/\(profileId.uuidString.lowercased())"
        self.body = body
    }
}

struct UpdateClientProfileBody: Encodable {
    let name: String?
    let isPrimary: Bool?
    let heightCm: Double?
    let dateOfBirth: String?
    let peopleType: String?
    let gender: String?
    let profileImage: String?
    let preferredBodyFatPct: Double?

    enum CodingKeys: String, CodingKey {
        case name
        case isPrimary
        case heightCm
        case dateOfBirth
        case peopleType
        case gender
        case profileImage
        case preferredBodyFatPct
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        // Partial PATCH: only send keys that are present (omit nils).
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(isPrimary, forKey: .isPrimary)
        try container.encodeIfPresent(heightCm, forKey: .heightCm)
        try container.encodeIfPresent(dateOfBirth, forKey: .dateOfBirth)
        try container.encodeIfPresent(peopleType, forKey: .peopleType)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(preferredBodyFatPct, forKey: .preferredBodyFatPct)
        try container.encodeIfPresent(profileImage, forKey: .profileImage)
    }
}

/// PATCH response only echoes provided fields — keep members optional for decode resilience.
struct UpdateClientProfileResponse: Decodable {
    let ok: Bool
    let profileId: UUID?
    let name: String?
    let isPrimary: Bool?
    let heightCm: Double?
    let dateOfBirth: String?
    let peopleType: String?
    let gender: String?
    let profileImage: String?
    let preferredBodyFatPct: Double?
}
