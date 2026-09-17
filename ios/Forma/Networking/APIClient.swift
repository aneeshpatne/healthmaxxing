//
//  APIClient.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//

import Foundation

/// The single "engine" every request flows through.
///
/// Responsibilities, in order:
/// 1. Build the URL from `APIConfig.baseURL` + the request's `path`.
/// 2. Append query parameters.
/// 3. Fetch a Clerk token when `requiresAuth` is true.
/// 4. Merge default + per-request headers.
/// 5. Encode the body to JSON via `AnyEncodable`.
/// 6. Send the request.
/// 7. Decode the response into the request's `Response` type.
final class APIClient {
    private let session: URLSession
    private let tokenProvider: AuthTokenProvider

    init(
        session: URLSession = .shared,
        tokenProvider: AuthTokenProvider = ClerkTokenProvider()
    ) {
        self.session = session
        self.tokenProvider = tokenProvider
    }

    @discardableResult
    func send<R: APIRequest>(_ request: R) async throws -> R.Response {
        // 1. Build the URL.
        guard var components = URLComponents(
            url: APIConfig.baseURL.appendingPathComponent(request.path),
            resolvingAgainstBaseURL: false
        ) else {
            throw APIError.invalidURL
        }

        // 2. Add query parameters.
        if !request.queryItems.isEmpty {
            components.queryItems = request.queryItems
        }

        guard let url = components.url else {
            throw APIError.invalidURL
        }

        // 3. Get an auth token if required.
        var headers = request.headers

        if request.requiresAuth {
            guard let token = try await tokenProvider.token() else {
                throw APIError.missingAuthToken
            }

            headers["Authorization"] = "Bearer \(token)"
        }

        // 4. Build the URLRequest.
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue

        // 5. Encode the body.
        if let body = request.body {
            headers["Content-Type"] = headers["Content-Type"] ?? "application/json"
            urlRequest.httpBody = try JSONEncoder().encode(AnyEncodable(body))
        }

        // Apply merged headers.
        for (key, value) in headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        // 6. Send the request.
        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if !(200..<300).contains(httpResponse.statusCode) {
            let responseBody = data.isEmpty ? nil : String(data: data, encoding: .utf8)
            throw APIError.serverError(httpResponse.statusCode, responseBody)
        }

        if data.isEmpty || httpResponse.statusCode == 204 {
            guard let emptyResponse = EmptyResponse() as? R.Response else {
                throw APIError.decodingError
            }

            return emptyResponse
        }

        // 7. Decode the response.
        do {
            return try JSONDecoder().decode(R.Response.self, from: data)
        } catch {
            throw APIError.decodingError
        }
    }
}

struct EmptyResponse: Decodable {}
