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
 Consolidate the logic that decides if the data should be
 saved inline, or in a separate file.  This is complicated
 by the fact that URLRequest, URLResponse and MockSequence
 all want to share this functionality and keep a single
 implementation in one place.  This is accomplished by adding
 a 'MockSerilazableRequest' and 'MockSerializableResponse'
 that return the proper request or response focused MockSerializableData
 object.  This allows for MockSequence to implement both and be able
 to generate both request and response file names.
 
 Also complicating matters is there is a small amount of implementation
 that needs to be the consistent across all implementations.  So, for something
 like 'requestHash', the same value is based on the request, so non-requests
 like response need to be able to return that value as well.
*/

public protocol MockSerializableData {
    var headers: [String: String]? { get }
    var url: URL? { get }
    var normalizedURL: URL? { get }
    var baseName: String { get }
    var dataSuffix: String? { get }
}

public protocol MockSerializableRequest: HashableMockData {
    var serializableRequest: MockSerializableData { get }
}

public protocol MockSerializableResponse: HashableMockData {
    var serializableResponse: MockSerializableData { get }
}

public protocol HashableMockData {
    var requestHash: String { get }
}

extension URLRequest: HashableMockData {
    public var requestHash: String {
        return serializedHashValue
    }
}

extension URLRequest: MockSerializableRequest {
    public var serializableRequest: MockSerializableData {
        return self
    }
}

extension MockSequence: MockSerializableRequest, MockSerializableResponse {
    public var serializableRequest: MockSerializableData {
        return request
    }
    public var serializableResponse: MockSerializableData {
        return response
    }
}

extension MockSequence: HashableMockData {
    public var requestHash: String {
        return request.serializedHashValue
    }
}

// This is the file name hash value that all the serialization uses.
private extension URLRequest {
    var serializedHashValue: String {
        var normalizedURL = url
        if let url = url {
            normalizedURL = MockDuck.delegate?.normalize(url: url)
        }

        var hashData = Data()

        if let urlData = normalizedURL?.absoluteString.data(using: .utf8) {
            hashData.append(urlData)
        }

        if
            let body = httpBody,
            let url = url,
            MockDuck.delegate?.useBodyInRequestHash(url: url) ?? true
        {
            hashData.append(body)
        }

        if !hashData.isEmpty {
            return String(MDCryptoUtils.md5String(hashData).prefix(8))
        } else {
            return ""
        }
    }
}

extension URLRequest: MockSerializableData {
    public var headers: [String: String]? {
        return allHTTPHeaderFields
    }
}

extension URLResponse: MockSerializableData {
    public var headers: [String: String]? {
        guard let httpResponse = self as? HTTPURLResponse else { return nil }
        return httpResponse.allHeaderFields as? [String: String]
    }
}

extension MockSerializableData {
    public var baseName: String {
        get {
            guard var name = normalizedURL?.host else { return "request" }
            if let path = normalizedURL?.path, path.count > 0 {
                name = name.appending(path)
            }
            return name
        }
    }

    public var normalizedURL: URL? {
        guard let url = url else { return nil }
        return MockDuck.delegate?.normalize(url: url)
    }

    public var dataSuffix: String? {
        if
            let headers = headers,
            let contentType = headers["Content-Type"]
        {
            if contentType.contains("image/jpeg") {
                return "jpg"
            } else if contentType.contains("image/png") {
                return "png"
            } else if contentType.contains("image/gif") {
                return "gif"
            } else if contentType.contains("application/json") {
                return "json"
            }
        }
        return nil
    }
}
