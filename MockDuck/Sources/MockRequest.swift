//
//  MockRequest.swift
//  MockDuck
//
//  Created by Sebastian Celis on 9/7/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

/// A very basic wrapper around URLRequest that allows us to read and write this data to disk
/// using Codable without having to make URLRequest itself conform to Codable.
final class MockRequest {
    var request: URLRequest

    private(set) lazy var normalizedRequest: URLRequest = {
        return MockDuck.delegate?.normalizedRequest(for: request) ?? request
    }()

    var serializedHashValue: String {
        let normalizedRequest = self.normalizedRequest

        var hashData = Data()

        if let urlData = normalizedRequest.url?.absoluteString.data(using: .utf8) {
            hashData.append(urlData)
        }

        if let body = normalizedRequest.httpBody {
            hashData.append(body)
        }

        return !hashData.isEmpty ? String(CryptoUtils.md5(hashData).prefix(8)) : ""
    }

    init(request: URLRequest) {
        self.request = request
    }
}

extension MockRequest: Codable {
    enum CodingKeys: String, CodingKey {
        case httpMethod = "method"
        case absoluteURL = "url"
        case statusCode = "status_code"
        case allHTTPHeaderFields = "headers"
        case httpBody = "body"
    }

    public convenience init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let url = try values.decode(URL.self, forKey: CodingKeys.absoluteURL)
        var request = URLRequest(url: url)

        request.httpMethod = try values.decodeIfPresent(String.self, forKey: CodingKeys.httpMethod)
        request.allHTTPHeaderFields = try values.decodeIfPresent([String: String].self, forKey: CodingKeys.allHTTPHeaderFields)

        // Decode the encoded string that was representing the body
        if
            let encodedBody = try values.decodeIfPresent(String.self, forKey: CodingKeys.httpBody),
            let decodedBody = EncodingUtils.decodeBody(encodedBody, contentType: request.contentType)
        {
            request.httpBody = decodedBody
        }

        self.init(request: request)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        if let method = request.httpMethod {
            try container.encode(method, forKey: CodingKeys.httpMethod)
        }

        if let url = request.url?.absoluteURL {
            try container.encode(url, forKey: CodingKeys.absoluteURL)
        }

        if let headers = request.allHTTPHeaderFields {
            try container.encode(headers, forKey: CodingKeys.allHTTPHeaderFields)
        }

        if
            request.dataSuffix == nil,
            let data = request.httpBody
        {
            let encodedBody = try EncodingUtils.encodeBody(data, contentType: request.contentType)
            try container.encode(encodedBody, forKey: CodingKeys.httpBody)
        }
    }
}
