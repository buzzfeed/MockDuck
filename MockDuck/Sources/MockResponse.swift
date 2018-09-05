//
//  URLResponseWrapper.swift
//  MockDuck
//
//  Created by Peter Walters on 4/2/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

/// A basic class that holds onto a URLResponse and its associated data.
public final class MockResponse {

    let response: URLResponse
    var responseData: Data?

    init(response: URLResponse, responseData: Data?) {
        self.response = response
        self.responseData = responseData
    }
}

// MARK: - Codable

extension MockResponse: Codable {

    enum CodingKeys: String, CodingKey {
        case response = "url"
        case responseHeaders = "headers"
        case responseCode = "status_code"
        case responseData = "data"
    }

    public convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let url = try container.decode(URL.self, forKey: CodingKeys.response)

        let statusCode = try? container.decode(Int.self, forKey: CodingKeys.responseCode)

        let headers = try? container.decode([String: String].self, forKey: CodingKeys.responseHeaders)

        var data: Data?
        if let body = try? container.decode(String.self, forKey: CodingKeys.responseData) {
            data = EncodingUtils.decodeBody(body, headers: headers)
        }

        if let response = HTTPURLResponse(url: url, statusCode: statusCode ?? 200, httpVersion: nil, headerFields: headers) {
            self.init(response: response, responseData: data)
        } else {
            throw MockDuckError.unableToInitializeURLResponse
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        var headers: [String: String]? = nil
        if let httpResponse = response as? HTTPURLResponse {
            headers = httpResponse.allHeaderFields as? [String: String]
            try container.encode(httpResponse.statusCode, forKey: CodingKeys.responseCode)
            try container.encode(headers, forKey: CodingKeys.responseHeaders)
        }

        if
            !shouldSaveStandaloneResponseData,
            let data = responseData,
            let body = try EncodingUtils.encodeBody(data, headers: headers)
        {
            // inline the body if not saved on the side
            try container.encode(body, forKey: CodingKeys.responseData)
        }

        if let url = response.url {
            try container.encode(url, forKey: CodingKeys.response)
        }
    }

    private var shouldSaveStandaloneResponseData: Bool {
        if let response = response as? HTTPURLResponse {
            return response.dataSuffix != nil
        } else if response.url != nil {
            // Assuming this is a download since it wasn't a URL response.
            return true
        }
        return false
    }
}
