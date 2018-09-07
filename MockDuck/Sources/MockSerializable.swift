//
//  MockSerializable.swift
//  MockDuck
//
//  Created by Peter Walters on 4/2/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation
import os

/**
 Consolidate the logic that decides if the data should be saved inline or in a separate file. This
 is complicated by the fact that URLRequest, URLResponse and MockRequestResponse all want to share
 this functionality. This is accomplished by adding the 'MockSerilazableRequest' and
 'MockSerializableResponse' protocols that return the proper request-focused or response-focused
 MockSerializableData object. This allows for MockRequestResponse to implement both and be able to
 generate both request and response file names.

 Also complicating matters is that there is a small amount of logic that needs to be consistent
 across all implementations.  So, for something like 'requestHash', the same value is based on the
 request, so the response object need to be able to return that value as well.
*/

protocol MockSerializableData {
    var headers: [String: String]? { get }
    var contentType: String? { get }
    var url: URL? { get }
    var normalizedURL: URL? { get }
    var baseName: String { get }
    var dataSuffix: String? { get }
}

protocol MockSerializableRequest: HashableMockData {
    var serializableRequest: MockSerializableData { get }
}

protocol MockSerializableResponse: HashableMockData {
    var serializableResponse: MockSerializableData { get }
}

protocol HashableMockData {
    var requestHash: String { get }
}

extension URLRequest: HashableMockData {
    var requestHash: String {
        return serializedHashValue
    }
}

extension URLRequest: MockSerializableRequest {
    var serializableRequest: MockSerializableData {
        return self
    }
}

extension MockRequestResponse: MockSerializableRequest, MockSerializableResponse {
    var serializableRequest: MockSerializableData {
        return request
    }

    var serializableResponse: MockSerializableData {
        return response
    }
}

extension MockRequestResponse: HashableMockData {
    var requestHash: String {
        return request.serializedHashValue
    }
}

// This is the file name hash value that all of the serialization uses.
private extension URLRequest {
    var serializedHashValue: String {
        let normalizedRequest = MockDuck.delegate?.normalizedRequest(for: self) ?? self

        var hashData = Data()

        if let urlData = normalizedRequest.url?.absoluteString.data(using: .utf8) {
            hashData.append(urlData)
        }

        if let body = normalizedRequest.httpBody {
            hashData.append(body)
        }

        if !hashData.isEmpty {
            return String(CryptoUtils.md5(hashData).prefix(8))
        } else {
            return ""
        }
    }
}

extension URLRequest: MockSerializableData {
    var headers: [String: String]? {
        return allHTTPHeaderFields
    }

    var contentType: String? {
        return headers?["Content-Type"]
    }
}

extension URLResponse: MockSerializableData {
    var headers: [String: String]? {
        guard let httpResponse = self as? HTTPURLResponse else { return nil }
        return httpResponse.allHeaderFields as? [String: String]
    }

    var contentType: String? {
        return headers?["Content-Type"] ?? mimeType
    }
}

extension MockSerializableData {
    var baseName: String {
        get {
            guard var name = normalizedURL?.host else { return "request" }
            if let path = normalizedURL?.path, path.count > 0 {
                name = name.appending(path)
            }
            return name
        }
    }

    var normalizedURL: URL? {
        guard let url = url else { return nil }
        return MockDuck.delegate?.normalizedRequest(for: URLRequest(url: url)).url ?? url
    }

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
        } else {
            return nil
        }
    }
}
