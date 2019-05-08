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
        let hash = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> [UInt8] in
            var hash = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            CC_MD5(bytes.baseAddress, CC_LONG(data.count), &hash)
            return hash
        }
        return hash.map { String(format: "%02hhx", $0) }.joined()
    }
}
