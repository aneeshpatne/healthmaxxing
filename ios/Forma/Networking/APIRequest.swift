//
//  APIRequest.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//

import Foundation

protocol APIRequest {
    associatedtype Response: Decodable

    var path: String { get }
    var method: HTTPMethod { get }

    var headers: [String: String] { get }
    var queryItems: [URLQueryItem] { get }
    var body: (any Encodable)? { get }

    var requiresAuth: Bool { get }
}
