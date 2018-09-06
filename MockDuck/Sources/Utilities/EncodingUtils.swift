//
//  EncodingUtils.swift
//  MockDuck
//
//  Created by Peter Walters on 4/12/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

final class EncodingUtils {
    private enum Constants: String {
        case json = "application/json"
        case text = "text/"
    }

    static func encodeBody(_ body: Data, contentType: String?) throws -> String? {
        if let contentType = contentType {

            // Text
            if contentType.hasPrefix(Constants.text.rawValue) {
                if let result = String(data: body, encoding: .utf8) {
                    return result
                }
            }

            // JSON
            if contentType.hasPrefix(Constants.json.rawValue) {
                // Parse the JSON so it can be pretty-formatted for output
                let data = try JSONSerialization.jsonObject(with: body, options: [])
                let output = try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted])
                return String(data: output, encoding: .utf8)
            }
        }

        // Base64
        return body.base64EncodedString(options: [])
    }

    static func decodeBody(_ body: String, contentType: String?) -> Data? {
        var retVal: Data? = nil

        if let contentType = contentType {
            // Text or JSON
            if contentType.hasPrefix(Constants.json.rawValue) || contentType.hasPrefix(Constants.text.rawValue) {
                // TODO: Use encoding if specified in headers
                retVal = body.data(using: String.Encoding.utf8)
            }
        } else {
            // Base64
            retVal = Data(base64Encoded: body, options: [])
        }

        return retVal
    }
}
