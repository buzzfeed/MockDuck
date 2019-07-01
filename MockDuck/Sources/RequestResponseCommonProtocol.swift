//
//  RequestResponseCommonProtocol.swift
//  MockDuck
//
//  Created by Sebastian Celis on 6/18/19.
//  Copyright © 2019 BuzzFeed, Inc. All rights reserved.
//

import Foundation

protocol RequestResponseCommonProtocol {
    var headers: [String: String]? { get }
    var contentType: String? { get }
}

extension RequestResponseCommonProtocol {
    var dataSuffix: String? {
        guard let contentType = contentType else { return nil }

        if contentType.contains("image/jpeg") {
            return "jpg"
        } else if contentType.contains("image/png") {
            return "png"
        } else if contentType.contains("image/gif") {
            return "gif"
        } else if contentType.contains("application/json") {
            return "json"
        } else if contentType.contains("application/x-www-form-urlencoded") {
            return "txt"
        } else if contentType.hasPrefix("text/") {
            var newContentType = contentType
            newContentType.removeFirst("text/".count)
            return newContentType
        } else {
            return nil
        }
    }
}

extension URLResponse: RequestResponseCommonProtocol {
    var headers: [String: String]? {
        guard let httpResponse = self as? HTTPURLResponse else { return nil }
        return httpResponse.allHeaderFields as? [String: String]
    }

    var contentType: String? {
        return headers?["Content-Type"] ?? mimeType
    }
}

extension URLRequest: RequestResponseCommonProtocol {
    var headers: [String: String]? {
        return allHTTPHeaderFields
    }

    var contentType: String? {
        return headers?["Content-Type"]
    }
}
