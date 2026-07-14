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
        self.path = "client/profiles/\(profileId.uuidString)"
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
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(isPrimary, forKey: .isPrimary)
        try container.encodeIfPresent(heightCm, forKey: .heightCm)
        try container.encodeIfPresent(dateOfBirth, forKey: .dateOfBirth)
        try container.encodeIfPresent(peopleType, forKey: .peopleType)
        try container.encodeIfPresent(gender, forKey: .gender)
        try container.encodeIfPresent(preferredBodyFatPct, forKey: .preferredBodyFatPct)

        if let profileImage {
            try container.encode(profileImage, forKey: .profileImage)
        } else {
            try container.encodeNil(forKey: .profileImage)
        }
    }
}

struct UpdateClientProfileResponse: Decodable {
    let ok: Bool
    let profileId: UUID
    let name: String
    let isPrimary: Bool
    let heightCm: Double
    let dateOfBirth: String
    let peopleType: String
    let gender: String
    let profileImage: String?
    let preferredBodyFatPct: Double
}
