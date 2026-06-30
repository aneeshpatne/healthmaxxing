//
//  HTTPMethod.swift
//  Forma
//
//  Created by Xcode Assistant on 30/06/26.
//

import Foundation

/// Common HTTP methods for requests.
public enum HTTPMethod: String {
    case get     = "GET"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
    case head    = "HEAD"
    case options = "OPTIONS"
}
