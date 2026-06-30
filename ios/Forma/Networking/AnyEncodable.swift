//
//  AnyEncodable.swift
//  Forma
//
//  Created by Aneesh Patne on 30/06/26.
//

import Foundation

/// A type-erased `Encodable` wrapper.
///
/// `APIRequest.body` is typed as `any Encodable`, which cannot be passed
/// directly to `JSONEncoder` (whose `encode` method is generic). `AnyEncodable`
/// boxes the concrete value and forwards encoding dynamically, allowing the
/// `APIClient` to encode any request body in one uniform code path.
struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init(_ value: some Encodable) {
        self.encode = value.encode
    }

    init(_ value: any Encodable) {
        self.encode = value.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}