//
//  MockRequestResponse.swift
//  MockDuck
//
//  Created by Peter Walters on 3/22/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

/// A basic container for holding a request, a response, and any associated data.
final class MockRequestResponse: Codable, CustomDebugStringConvertible {

    enum MockFileTarget {
        case request
        case requestBody
        case responseData
    }

    // MARK: - Properties

    var request: URLRequest {
        get {
            return requestWrapper.request
        }
        set {
            requestWrapper.request = newValue
        }
    }

    var response: URLResponse? {
        return responseWrapper?.response
    }

    var responseData: Data? {
        get {
            return responseWrapper?.responseData
        }
        set {
            responseWrapper?.responseData = newValue
        }
    }

    private(set) lazy var normalizedRequest: URLRequest = {
        return MockDuck.delegate?.normalizedRequest(for: request) ?? request
    }()

    let requestWrapper: MockRequest
    var responseWrapper: MockResponse?

    // MARK: - Initializers

    init(request: URLRequest) {
        self.requestWrapper = MockRequest(request: request)
        self.responseWrapper = nil
    }

    init(request: URLRequest, mockResponse: MockResponse) {
        self.requestWrapper = MockRequest(request: request)
        self.responseWrapper = mockResponse
    }

    init(request: URLRequest, response: URLResponse, responseData: Data?) {
        self.requestWrapper = MockRequest(request: request)
        self.responseWrapper = MockResponse(response: response, responseData: responseData)
    }

    // MARK: - Disk Utilities

    func fileName(for type: MockFileTarget) -> String? {
        guard let baseName = serializedBaseName else { return nil }
        let hashValue = serializedHashValue
        var componentSuffix = ""
        var pathExtension: String?

        switch type {
        case .request:
            pathExtension = "json"
        case .requestBody:
            componentSuffix = "-request"
            pathExtension = request.dataSuffix
        case .responseData:
            componentSuffix = "-response"
            pathExtension = response?.dataSuffix
        }

        // We only construct a fileName if there is a valid path extension. The only way
        // pathExtension can be nil here is if this is a data blob that we do not support writing as
        // an associated file. In this scenario, this data is encoded and stored in the JSON itself
        // instead of as a separate, associated file.
        var fileName: String?
        if let pathExtension = pathExtension {
            fileName = "\(baseName)-\(hashValue)\(componentSuffix).\(pathExtension)"
        }

        return fileName
    }

    var serializedHashValue: String {
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

    private var serializedBaseName: String? {
        guard
            let url = normalizedRequest.url,
            let host = url.host else
        {
            return nil
        }

        if url.path.count > 0 {
            return host.appending(url.path)
        } else {
            return host
        }
    }

    // MARK: - Codable

    enum CodingKeys: String, CodingKey {
        case requestWrapper = "request"
        case responseWrapper = "response"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        requestWrapper = try container.decode(MockRequest.self, forKey: .requestWrapper)
        responseWrapper = try container.decodeIfPresent(MockResponse.self, forKey: .responseWrapper)
    }
    
    // MARK: Debug
    
    public var debugDescription: String {
        var result = "\n"
        
        if let request = fileName(for: .request) {
            result.append("Request: \(request)\n")
            result.append("\t\(requestWrapper)\n")
        }
        if let requestBody = fileName(for: .requestBody) {
            result.append("Request Body: \(requestBody)\n")
        }
        if let responseData = fileName(for: .responseData) {
            result.append("Response Data: \(responseData)\n")
                
            if let response = responseWrapper {
                result.append("\t\(response)\n")
            }
        }

        return result
    }
}
