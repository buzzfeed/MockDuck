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
    func loadResponse(for requestResponse: MockRequestResponse) -> Bool {
        guard let fileName = requestResponse.fileName(for: .request) else { return false }
        let request = requestResponse.request

        var loadedPath: String?
        var loadedResponse: MockResponse?
        if let response = checkRequestHandlers(for: request) {
            loadedResponse = response
        } else if let response = loadResponseFile(relativePath: fileName, baseURL: loadingURL) {
            loadedPath = loadingURL?.path ?? "" + fileName
            loadedResponse = response.responseWrapper
        } else if let response = loadResponseFile(relativePath: fileName, baseURL: recordingURL) {
            loadedPath = recordingURL?.path ?? "" + fileName
            loadedResponse = response.responseWrapper
        } else {
            os_log("Request %@ not found on disk. Expected file name: %@", log: MockDuck.log, type: .debug, "\(request)", fileName)
        }
        
        if let response = loadedResponse {
            requestResponse.responseWrapper = response
            if let path = loadedPath {
                os_log("Loading request %@ from: %@",
                log: MockDuck.log,
                type: .debug,
                "\(request)",
                path)
            }
            return true
        }
        return false
    }
    
    /// Takes a URL and attempts to parse the file at that location into a MockRequestResponse
    /// If the file doesn't exist, or isn't in the expected MockDuck format, nil is returned
    ///
    /// - Parameter targetURL: URL that should be loaded from file
    /// - Returns: MockRequestResponse if the request exists at that URL
    func loadResponseFile(relativePath: String, baseURL: URL?) -> MockRequestResponse? {
        guard let baseURL = baseURL else { return nil }
        let targetURL = baseURL.appendingPathComponent(relativePath)
        guard FileManager.default.fileExists(atPath: targetURL.path) else { return nil}
        
        let decoder = JSONDecoder()
        
        do {
            let data = try Data(contentsOf: targetURL)
            
            let response = try decoder.decode(MockRequestResponse.self, from: data)
            
            // Load the response data if the format is supported.
            // This should be the same filename with a different extension.
            if let dataFileName = response.fileName(for: .responseData) {
                let dataURL = baseURL.appendingPathComponent(dataFileName)
                response.responseData = try? Data(contentsOf: dataURL)
            }
            
            return response
        } catch {
            os_log("Error decoding JSON: %@", log: MockDuck.log, type: .error, "\(error)")
        }
        return nil
    }
    
    /// Takes a passed in hostname and returns all the recorded mocks for that URL.
    /// If an empty string is passed in, all recordings will be returned.
    ///
    /// - Parameter hostname: String representing the hostname to load requests from.
    /// - Returns: An array of MockRequestResponse for each request under that domain
    func getResponses(for hostname: String) -> [MockRequestResponse] {
        guard let recordingURL = recordingURL else { return [] }
        
        let baseURL = recordingURL.resolvingSymlinksInPath()
        var responses = [MockRequestResponse]()
        let targetURL = baseURL.appendingPathComponent(hostname)
        
        let results = FileManager.default.enumerator(
            at: targetURL,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [])
        
        if let results = results {
            for case let item as URL in results {
                var isDir = ObjCBool(false)
                let itemURL = item.resolvingSymlinksInPath()

                /// Check if the item:
                /// 1) isn't a directory
                /// 2) doesn't end in '-response' (a sidecar file)
                /// If so, load it using loadResponseFile so any associated
                ///  '-response' file is also loaded with the repsonse.
                if
                    FileManager.default.fileExists(atPath: itemURL.path, isDirectory: &isDir),
                    !isDir.boolValue,
                    !itemURL.lastPathComponent.contains("-response"),
                    let relativePath = itemURL.pathRelative(to: baseURL),
                    let response = loadResponseFile(relativePath: relativePath, baseURL: recordingURL)
                {
                    responses.append(response)
                }
            }
        }
        
        return responses
    }

    /// If recording is enabled, this method saves the request to the filesystem. If the request
    /// body or the response data are of a certain type 'jpg/png/gif/json', the request is saved
    /// into a separate file that lives along side the recorded request.
    ///
    /// - Parameter requestResponse: MockRequestResponse containing the request, response, and data
    func record(requestResponse: MockRequestResponse) {
        guard
            let recordingURL = recordingURL,
            let outputFileName = requestResponse.fileName(for: .request)
            else { return }

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
                if let requestBodyFileName = requestResponse.fileName(for: .requestBody) {
                    let requestBodyURL = recordingURL.appendingPathComponent(requestBodyFileName)
                    let body = requestResponse.request.httpBody ?? requestResponse.request.httpBodyStreamData
                    try body?.write(to: requestBodyURL, options: [.atomic])
                }

                // write out response data if the format is supported.
                // This should be the same filename with a different extension.
                if let dataFileName = requestResponse.fileName(for: .responseData) {
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


extension URL {
    func pathRelative(to url: URL) -> String? {
        guard
            host == url.host,
            scheme == url.scheme
        else { return nil }

        let components = self.standardized.pathComponents
        let baseComponents = url.standardized.pathComponents
        
        if components.count < baseComponents.count { return nil }
        for (index, baseComponent) in baseComponents.enumerated() {
            let component = components[index]
            if component != baseComponent { return nil }
        }

        return components[baseComponents.count..<components.count].joined(separator: "/")
    }
}
