//
//  APIErrors.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//

enum APIError: Error {
    case invalidURL
    case invalidResponse
    case missingAuthToken
    case serverError(Int, String?)
    case decodingError
}
