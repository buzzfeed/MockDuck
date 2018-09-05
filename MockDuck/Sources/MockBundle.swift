//
//  MockDuckContainer.swift
//  MockDuck
//
//  Created by Peter Walters on 3/26/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation
import os

/// MockBundle holds a set of MockSequence (request/response/data pairings).  It is
/// responsible for the persistence and loading of MockSequences
public class MockBundle {

    public typealias RequestMock = (URLRequest) -> MockResponse?
    private var requestMocks = [RequestMock]()

    public var baseURL: URL?
    public var recordURL: URL?

    public init(baseURL: URL? = nil, recordURL: URL? = nil) {
        self.baseURL = baseURL
        self.recordURL = recordURL
    }

    var recording: Bool {
        return recordURL != nil
    }

    public func hasRegisteredRequestMocks() -> Bool {
        return !requestMocks.isEmpty
    }

    public func registerRequestMock(with block: @escaping RequestMock) {
        requestMocks.append(block)
    }

    public func unregisterAllRequestMocks() {
        requestMocks.removeAll()
    }

    // MARK: Save/Load requests

    func checkForRegisteredResponse(request: URLRequest) -> MockResponse? {
        for block in requestMocks {
            if let result = block(request) {
                return result
            }
        }
        return nil
    }

    /// Checks for the existence of a URLRequest in the bundle and loads it if present. If the
    /// request body or the response data are of a certain type 'jpg/png/gif/json', the request is
    /// loaded from the separate file that lives along side the recorded request.
    ///
    /// - Parameter request: URLRequest to attempt to load
    /// - Returns: The MockSequence, if it can be loaded
    func loadRequest(request: URLRequest) -> MockSequence? {
        guard let fileName = MockSequence.fileName(for: .request(request)) else { return nil }

        var targetURL: URL?
        var targetBaseURL: URL?

        if let response = checkForRegisteredResponse(request: request) {
            return MockSequence(request: request, mockResponse: response)
        } else if
            let inputURL = baseURL?.appendingPathComponent(fileName),
            FileManager.default.fileExists(atPath: inputURL.path)
        {
            os_log("Loading request %@ from: %@", log: MockDuck.log, type: .debug, "\(request)", inputURL.path)
            targetURL = inputURL
            targetBaseURL = baseURL
        } else if
            let inputURL = recordURL?.appendingPathComponent(fileName),
            FileManager.default.fileExists(atPath: inputURL.path)
        {
            os_log("Loading request %@ from: %@", log: MockDuck.log, type: .debug, "\(request)", inputURL.path)
            targetURL = inputURL
            targetBaseURL = recordURL
        } else {
            os_log("Request %@ not found on disk. Expected file name: %@", log: MockDuck.log, type: .debug, "\(request)", fileName)
        }

        var result: MockSequence? = nil
        if
            let targetURL = targetURL,
            let targetBaseURL = targetBaseURL
        {
            let decoder = JSONDecoder()
            do {
                let data = try Data(contentsOf: targetURL)

                var sequence: MockSequence = try decoder.decode(MockSequence.self, from: data)

                // load the response data if the format is supported.
                // This should be the same filename with a different extension.
                if let dataFileName = MockSequence.fileName(for: .responseData(sequence, sequence)) {
                    let dataURL = targetBaseURL.appendingPathComponent(dataFileName)
                    sequence.responseData = try Data(contentsOf: dataURL)
                }

                // load the request body if the format is supported.
                // This should be the same filename with a different extension.
                if let bodyFileName = MockSequence.fileName(for: .requestBody(sequence)) {
                    let bodyURL = targetBaseURL.appendingPathComponent(bodyFileName)
                    sequence.request.httpBody = try Data(contentsOf: bodyURL)
                }

                result = sequence
            } catch {
                os_log("Error decoding JSON: %@", log: MockDuck.log, type: .error, "\(error)")
            }
        }

        return result
    }

    /// If recording is enabled, this method saves the request to the filesystem. If the request
    /// body or the response data are of a certain type 'jpg/png/gif/json', the request is saved
    /// into a separate file that lives along side the recorded request.
    ///
    /// - Parameter sequence: MockSequence containing the request,response & data
    func saveRequest(sequence: MockSequence) {
        guard
            let recordURL = recordURL,
            let outputFileName =  MockSequence.fileName(for: .request(sequence))
            else { return }

        do {
            let outputURL = recordURL.appendingPathComponent(outputFileName)
            try createOutputDirectory(url: outputURL)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]

            let data = try encoder.encode(sequence)
            let result = String(data: data, encoding: .utf8)

            if let data = result?.data(using: .utf8) {
                try data.write(to: outputURL, options: [.atomic])

                // write out request body if the format is supported.
                // This should be the same filename with a different extension.
                if let requestBodyFileName = MockSequence.fileName(for: .requestBody(sequence)) {
                    let requestBodyURL = recordURL.appendingPathComponent(requestBodyFileName)
                    try sequence.request.httpBody?.write(to: requestBodyURL, options: [.atomic])
                }

                // write out response data if the format is supported.
                // This should be the same filename with a different extension.
                if let dataFileName = MockSequence.fileName(for: .responseData(sequence, sequence)) {
                    let dataURL = recordURL.appendingPathComponent(dataFileName)
                    try sequence.responseData?.write(to: dataURL, options: [.atomic])
                }

                os_log("Persisted network request to: %@", log: MockDuck.log, type: .debug, outputURL.path)
            } else {
                os_log("Failed to persist request for: %@", log: MockDuck.log, type: .error, "\(sequence)")
            }
        } catch {
            os_log("Failed to persist request: %@", log: MockDuck.log, type: .error, "\(error)")
        }
    }

    // Mark: Utilities

    private func createOutputDirectory(url outputPath: URL) throws {
        let fileManager = FileManager.default
        let outputDirectory = outputPath.deletingLastPathComponent()
        if !fileManager.fileExists(atPath: outputDirectory.path) {
            try fileManager.createDirectory(atPath: outputDirectory.path,
                                            withIntermediateDirectories: true,
                                            attributes: nil)
        }
    }
}
