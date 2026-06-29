//
//  FormaBackendClient.swift
//  Forma
//
//  Created by Codex on 29/06/26.
//

import Foundation

enum FormaBackendClient {
    private static let baseURL = URL(string: "https://forma.aneeshpatne.com")!

    static func authenticate(clerkToken: String) async throws {
        let url = baseURL.appending(path: "client/auth/me")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(clerkToken)", forHTTPHeaderField: "Authorization")

        let (_, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              200..<300 ~= httpResponse.statusCode else {
            throw BackendError.unexpectedResponse
        }
    }
}

private enum BackendError: Error {
    case unexpectedResponse
}
