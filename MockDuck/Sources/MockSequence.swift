//
//  MockSequence.swift
//  MockDuck
//
//  Created by Peter Walters on 3/22/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

/// Basic container for holding request/response/data
public struct MockSequence: Codable {

    // MARK: - Properties

    var request: URLRequest
    let recordedAt: Date
    let loadedFromDisk: Bool
    
    private var responseWrapper: MockResponse
    var response: URLResponse {
        return responseWrapper.response
    }

    var responseData: Data? {
        get {
            return responseWrapper.responseData
        }
        set {
            responseWrapper.responseData = newValue
        }
    }

    // MARK: - CodingKeys

    enum CodingKeys: String, CodingKey {
        case request
        case responseWrapper = "response"
        case recordedAt
    }

    // MARK: - Initializers

    public init(request: URLRequest,
         response: URLResponse,
         responseData: Data? = nil,
         recordedAt: Date = Date())
    {
        self.request = request
        self.responseWrapper = MockResponse(response: response, responseData: responseData)
        self.recordedAt = recordedAt
        self.loadedFromDisk = false
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        request = try container.decode(URLRequest.self, forKey: .request)
        responseWrapper = try container.decode(MockResponse.self, forKey: .responseWrapper)
        recordedAt = try container.decode(Date.self, forKey: .recordedAt)
        loadedFromDisk = true
    }

    public enum MockFileTarget {
        case request(MockSerializableRequest)
        case requestBody(MockSerializableRequest)
        case responseData(MockSerializableRequest, MockSerializableResponse)
    }

    public static func fileURL(for type: MockFileTarget, baseURL: URL) -> URL? {
        var data: MockSerializableData
        var hashValue: String
        var componentSuffix: String = ""
        var baseName: String = ""
        var pathExtension: String?

        switch type {
        case .request(let request):
            hashValue = request.requestHash
            data = request.serializableRequest
            baseName = data.baseName
            pathExtension = "json"
        case .requestBody(let request):
            hashValue = request.requestHash
            data = request.serializableRequest
            baseName = data.baseName
            componentSuffix = "-request"
            pathExtension = data.dataSuffix
        case .responseData(let request, let response):
            hashValue = response.requestHash
            data = response.serializableResponse
            baseName = request.serializableRequest.baseName
            componentSuffix = "-response"
            pathExtension = data.dataSuffix
        }

        // We only construct a URL if there is a valid path extension. The only way pathExtension
        // can be nil here is if this is a data blob that we do not support writing as an associated
        // file. In this scenario, this data is encoded and stored in the JSON itself instead of
        // as a separate, associated file.
        var url: URL?
        if let pathExtension = pathExtension {
            url = baseURL
                .appendingPathComponent("\(baseName)-\(hashValue)\(componentSuffix)")
                .appendingPathExtension(pathExtension)
        }

        return url
    }
}

public extension MockSequence {
    public init(request: URLRequest, mockResponse: MockResponse) {
        self.init(request: request, response: mockResponse.response, responseData: mockResponse.responseData)
    }
}
