//
//  AuthTokenProvider.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//

import Foundation
import ClerkKit

/// Abstracts how an auth token is obtained so the networking layer never
/// imports (or depends on) a specific identity provider.
///
/// This is the **only** file in `Networking` that imports `Clerk`. To swap
/// authentication providers, replace only this file.
protocol AuthTokenProvider {
    func token() async throws -> String?
}

/// Default implementation backed by Clerk.
final class ClerkTokenProvider: AuthTokenProvider {
    func token() async throws -> String? {
        guard let session = Clerk.shared.session else {
            return nil
        }

        return try await session.getToken()
    }
}
