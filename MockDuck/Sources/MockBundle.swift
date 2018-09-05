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
        var targetURL: URL?
        var targetBaseURL: URL?

        if let response = checkForRegisteredResponse(request: request) {
            return MockSequence(request: request, mockResponse: response)
        } else if
            let baseURL = baseURL,
            let inputPath = MockSequence.fileURL(for: .request(request), baseURL: baseURL),
            FileManager.default.fileExists(atPath: inputPath.path)
        {
            os_log("Loading request %@ from: %@", log: MockDuck.log, type: .debug, "\(request)", inputPath.path)
            targetURL = inputPath
            targetBaseURL = baseURL
        } else if
            let recordURL = recordURL,
            let inputPath = MockSequence.fileURL(for: .request(request), baseURL: recordURL),
            FileManager.default.fileExists(atPath: inputPath.path)
        {
            os_log("Loading request %@ from: %@", log: MockDuck.log, type: .debug, "\(request)", inputPath.path)
            targetURL = inputPath
            targetBaseURL = recordURL
        } else if let path = MockSequence.fileURL(for: .request(request), baseURL: URL(fileURLWithPath: "")) {
            os_log("Request %@ not found on disk. Expected path: %@", log: MockDuck.log, type: .debug, "\(request)", path.path)
            return nil
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
                if let dataPath = MockSequence.fileURL(for: .responseData(sequence, sequence), baseURL: targetBaseURL) {
                    sequence.responseData = try Data(contentsOf: dataPath)
                }

                // load the request body if the format is supported.
                // This should be the same filename with a different extension.
                if let bodyPath = MockSequence.fileURL(for: .requestBody(sequence), baseURL: targetBaseURL) {
                    sequence.request.httpBody = try Data(contentsOf: bodyPath)
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
            let outputPath =  MockSequence.fileURL(for: .request(sequence), baseURL: recordURL)
            else { return }

        do {
            try createOutputDirectory(url: outputPath)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]

            let data = try encoder.encode(sequence)
            let result = String(data: data, encoding: .utf8)

            if let data = result?.data(using: .utf8) {
                try data.write(to: outputPath, options: [.atomic])

                // write out request body if the format is supported.
                // This should be the same filename with a different extension.
                if let requestBodyPath = MockSequence.fileURL(for: .requestBody(sequence), baseURL: recordURL) {
                    try sequence.request.httpBody?.write(to: requestBodyPath, options: [.atomic])
                }

                // write out response data if the format is supported.
                // This should be the same filename with a different extension.
                if let dataOutputPath = MockSequence.fileURL(for: .responseData(sequence, sequence), baseURL: recordURL) {
                    try sequence.responseData?.write(to: dataOutputPath, options: [.atomic])
                }

                os_log("Persisted network request to: %@", log: MockDuck.log, type: .debug, outputPath.path)
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
