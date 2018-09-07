//
//  CryptoUtils.swift
//  MockDuck
//
//  Created by Sebastian Celis on 9/7/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import CommonCrypto
import Foundation

final class CryptoUtils {
    static func md5(_ data: Data) -> String {
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        _ = digestData.withUnsafeMutableBytes { digestBytes in
            data.withUnsafeBytes { messageBytes in
                CC_MD5(messageBytes, CC_LONG(data.count), digestBytes)
            }
        }

        return digestData.map { String(format: "%02hhx", $0) }.joined()
    }
}
