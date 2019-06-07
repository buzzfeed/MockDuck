//
//  SerializationUtils.swift
//  MockDuck
//
//  Created by Sebastian Celis on 9/5/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

final class SerializationUtils {

    /// The different types of files that MockDuck can read and write when mocking a request.
    enum MockFileTarget {
        case request(MockSerializableRequest)
        case requestBody(MockSerializableRequest)
        case responseData(MockSerializableRequest, MockSerializableResponse)
    }

    /// Used to determine the file name for a particular piece of data that we may want to
    /// serialize to or from disk.
    static func fileName(for hash: String, type: MockFileTarget) -> String? {
        var data: MockSerializableData
        var componentSuffix: String = ""
        var baseName: String = ""
        var pathExtension: String?

        switch type {
        case .request(let request):
            data = request.serializableRequest
            baseName = data.baseName
            pathExtension = "json"
        case .requestBody(let request):
            data = request.serializableRequest
            baseName = data.baseName
            componentSuffix = "-request"
            pathExtension = data.dataSuffix
        case .responseData(let request, let response):
            data = response.serializableResponse
            baseName = request.serializableRequest.baseName
            componentSuffix = "-response"
            pathExtension = data.dataSuffix
        }

        // We only construct a fileName if there is a valid path extension. The only way
        // pathExtension can be nil here is if this is a data blob that we do not support writing as
        // an associated file. In this scenario, this data is encoded and stored in the JSON itself
        // instead of as a separate, associated file.
        var fileName: String?
        if let pathExtension = pathExtension {
            fileName = "\(baseName)-\(hash)\(componentSuffix).\(pathExtension)"
        }

        return fileName
    }

    static func prefix(_ filename: String, withOrder order: Int) -> String {

         var components = filename.components(separatedBy: "/")
         let lastFilename = components.removeLast()
         return "\(components.joined(separator: "/"))/\(order)-\(lastFilename)"
    }
}
