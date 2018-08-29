//
//  EncodingUtils.swift
//  MockDuck
//
//  Created by Peter Walters on 4/12/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation

public class EncodingUtils {
    enum Constants: String {
        case content_type = "Content-Type"
        case json = "application/json"
        case text = "text/"
    }

    static func encodeBody(_ body: Data, headers: [String: String]? = nil) -> String? {
        if let contentType = headers?[Constants.content_type.rawValue] {

            // Text
            if contentType.hasPrefix(Constants.text.rawValue) {
                if let result = String(data: body, encoding: .utf8) {
                    return result
                }
            }

            // JSON
            if contentType.hasPrefix(Constants.json.rawValue) {
                do {
                    // Parse the JSON so it can be pretty-formatted for output
                    let data = try JSONSerialization.jsonObject(with: body, options: [])
                    let output = try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted])
                    return String(data: output, encoding: .utf8)
                } catch {
                    return nil
                }
            }
        }

        // Base64
        return body.base64EncodedString(options: [])
    }
    
    static func decodeBody(_ body: Any?, headers: [String: String]? = nil) -> Data? {
        guard let body = body else { return nil }

        var retVal: Data? = nil
        if let contentType = headers?[Constants.content_type.rawValue] {
            // Text or JSON
            if
                let string = body as? String,
                contentType.hasPrefix(Constants.json.rawValue) || contentType.hasPrefix(Constants.text.rawValue)
            {
                // TODO: Use encoding if specified in headers
                retVal = string.data(using: String.Encoding.utf8)
            }
        } else if let base64 = body as? String {
            // Base64
            retVal = Data(base64Encoded: base64, options: [])
        }

        return retVal
    }
}
