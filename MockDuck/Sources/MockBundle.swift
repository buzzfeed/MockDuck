//
//  MockDuckContainer.swift
//  MockDuck
//
//  Created by Peter Walters on 3/26/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation
import os

/// MockBundle is responsible for loading requests from disk and optionally persisting them when
/// `recordingURL` is set.
final class MockBundle {

    var loadingURL: URL?
    var recordingURL: URL?

    init() {
    }

    // MARK: - Loading and Recording Requests

    /// Checks for the existence of a URLRequest in the bundle and loads it if present. If the
    /// request body or the response data are of a certain type 'jpg/png/gif/json', the request is
    /// loaded from the separate file that lives along side the recorded request.
    ///
    /// - Parameter request: URLRequest to attempt to load
    /// - Returns: The MockRequestResponse, if it can be loaded
    func loadRequestResponse(for request: URLRequest, hash: String) -> MockRequestResponse? {
        print("hash:::::::", hash)
        guard let fileName = SerializationUtils.fileName(for: .request(request), hash: hash) else { return nil }

        print("--------", #function, fileName)

        var targetURL: URL?
        var targetLoadingURL: URL?

        if let response = checkRequestHandlers(for: request) {
            return MockRequestResponse(request: request, mockResponse: response)
        } else if
            let inputURL = loadingURL?.appendingPathComponent(fileName),
            FileManager.default.fileExists(atPath: inputURL.path)
        {
            os_log("Loading request %@ from: %@", log: MockDuck.log, type: .debug, "\(request)", inputURL.path)
            targetURL = inputURL
            targetLoadingURL = loadingURL
        } else if
            let inputURL = recordingURL?.appendingPathComponent(fileName),
            FileManager.default.fileExists(atPath: inputURL.path)
        {
            os_log("Loading request %@ from: %@", log: MockDuck.log, type: .debug, "\(request)", inputURL.path)
            targetURL = inputURL
            targetLoadingURL = recordingURL
        } else {
            os_log("Request %@ not found on disk. Expected file name: %@", log: MockDuck.log, type: .debug, "\(request)", fileName)
        }

        var result: MockRequestResponse? = nil
        if
            let targetURL = targetURL,
            let targetLoadingURL = targetLoadingURL
        {
            let decoder = JSONDecoder()
            do {
                let data = try Data(contentsOf: targetURL)

                let sequence: MockRequestResponse = try decoder.decode(MockRequestResponse.self, from: data)

                // Load the response data if the format is supported.
                // This should be the same filename with a different extension.
                if let dataFileName = SerializationUtils.fileName(for: .responseData(sequence, sequence), hash: hash) {
                    let dataURL = targetLoadingURL.appendingPathComponent(dataFileName)
                    sequence.responseData = try Data(contentsOf: dataURL)
                }

                // Load the request body if the format is supported.
                // This should be the same filename with a different extension.
                if let bodyFileName = SerializationUtils.fileName(for: .requestBody(sequence), hash: hash) {
                    let bodyURL = targetLoadingURL.appendingPathComponent(bodyFileName)
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
    /// - Parameter requestResponse: MockRequestResponse containing the request, response, and data
    func record(requestResponse: MockRequestResponse, hash: String) {
        guard
            let recordingURL = recordingURL,
            let outputFileName =  SerializationUtils.fileName(for: .request(requestResponse), hash: hash)
            else { return }

                print("--------", #function, outputFileName)

        do {
            let outputURL = recordingURL.appendingPathComponent(outputFileName)
            try createOutputDirectory(url: outputURL)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted]

            let data = try encoder.encode(requestResponse)
            let result = String(data: data, encoding: .utf8)

            if let data = result?.data(using: .utf8) {
                try data.write(to: outputURL, options: [.atomic])

                // write out request body if the format is supported.
                // This should be the same filename with a different extension.
                if let requestBodyFileName = SerializationUtils.fileName(for: .requestBody(requestResponse), hash: hash) {
                    let requestBodyURL = recordingURL.appendingPathComponent(requestBodyFileName)
                    try requestResponse.request.httpBody?.write(to: requestBodyURL, options: [.atomic])
                }

                // write out response data if the format is supported.
                // This should be the same filename with a different extension.
                if let dataFileName = SerializationUtils.fileName(for: .responseData(requestResponse, requestResponse), hash: hash) {
                    let dataURL = recordingURL.appendingPathComponent(dataFileName)
                    try requestResponse.responseData?.write(to: dataURL, options: [.atomic])
                }

                os_log("Persisted network request to: %@", log: MockDuck.log, type: .debug, outputURL.path)
            } else {
                os_log("Failed to persist request for: %@", log: MockDuck.log, type: .error, "\(requestResponse)")
            }
        } catch {
            os_log("Failed to persist request: %@", log: MockDuck.log, type: .error, "\(error)")
        }
    }

    // MARK: - Registered Request Handlers

    private var requestHandlers = [MockDuck.RequestHandler]()

    func hasRegisteredRequestHandlers() -> Bool {
        return !requestHandlers.isEmpty
    }

    func registerRequestHandler(_ handler: @escaping MockDuck.RequestHandler) {
        requestHandlers.append(handler)
    }

    func unregisterAllRequestHandlers() {
        requestHandlers.removeAll()
    }

    private func checkRequestHandlers(for request: URLRequest) -> MockResponse? {
        for block in requestHandlers {
            if let result = block(request) {
                return result
            }
        }

        return nil
    }

    // Mark: - Utilities

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
