//
//  CreateClientProfileRequest.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//

import Foundation

struct CreateClientProfileRequest: APIRequest {
    typealias Response = CreateClientProfileResponse

    let path = "client/register/profiles/v2"
    let method: HTTPMethod = .post
    let headers: [String: String] = [:]
    let queryItems: [URLQueryItem] = []
    let body: (any Encodable)?
    let requiresAuth = true

    init(body: CreateClientProfileBody) {
        self.body = body
    }
}

struct CreateClientProfileBody: Encodable {
    let name: String
    let isPrimary: Bool
    let heightCm: Double
    let dateOfBirth: String
    let peopleType: String
    let gender: String
    let profileImage: String?
    let preferredBodyFatPct: Double
}

struct CreateClientProfileResponse: Decodable {
    let ok: Bool
    let profileId: String
    let accountId: String
    let name: String
    let isPrimary: Bool
    let heightCm: Double
    let dateOfBirth: String
    let peopleType: String
    let gender: String
    let profileImage: String?
    let preferredBodyFatPct: Double
}
