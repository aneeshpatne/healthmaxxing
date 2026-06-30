//
//  GetClientProfilesRequest.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//

import Foundation

struct GetClientProfilesRequest: APIRequest {
    typealias Response = GetClientProfilesResponse

    let path = "client/profiles"
    let method: HTTPMethod = .get
    let headers: [String: String] = [:]
    let queryItems: [URLQueryItem] = []
    let body: (any Encodable)? = nil
    let requiresAuth = true
}

struct GetClientProfilesResponse: Decodable {
    let ok: Bool
    let users: [ClientProfile]
}

struct ClientProfile: Decodable, Identifiable {
    let id: UUID
    let accountId: UUID
    let name: String
    let mailAddress: String
    let isPrimary: Bool
    let heightCm: Double?
    let dateOfBirth: String?
    let peopleType: String?
    let gender: String?
    let profileImage: String?
    let preferredBodyFatPct: Double?
    let createdAt: String
}
