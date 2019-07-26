//
//  RequestResponseCommonProtocol.swift
//  MockDuck
//
//  Created by Sebastian Celis on 6/18/19.
//  Copyright © 2019 BuzzFeed, Inc. All rights reserved.
//

import Foundation

protocol RequestResponseCommonProtocol {
    var headers: [String: String]? { get }
    var contentType: String? { get }
}

extension RequestResponseCommonProtocol {
    var dataSuffix: String? {
        guard let contentType = contentType else { return nil }

        if contentType.contains("image/jpeg") {
            return "jpg"
        } else if contentType.contains("image/png") {
            return "png"
        } else if contentType.contains("image/gif") {
            return "gif"
        } else if contentType.contains("application/json") {
            return "json"
        } else {
            return nil
        }
    }
}

extension URLResponse: RequestResponseCommonProtocol {
    var headers: [String: String]? {
        guard let httpResponse = self as? HTTPURLResponse else { return nil }
        return httpResponse.allHeaderFields as? [String: String]
    }

    var contentType: String? {
        return headers?["Content-Type"] ?? mimeType
    }
}

extension URLRequest: RequestResponseCommonProtocol {
    var headers: [String: String]? {
        return allHTTPHeaderFields
    }

    var contentType: String? {
        return headers?["Content-Type"]
    }
    
    var httpBodyStreamData: Data? {
            
        guard let bodyStream = self.httpBodyStream else { return nil }
        bodyStream.open()
        let bufferSize: Int = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        var dat = Data()
        
        while bodyStream.hasBytesAvailable {
            let readDat = bodyStream.read(buffer, maxLength: bufferSize)
            dat.append(buffer, count: readDat)
        }
        
        buffer.deallocate()
        bodyStream.close()
        return dat
    }
}
