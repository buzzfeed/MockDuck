//
//  CryptoTests.swift
//  MockDuckTests
//
//  Created by Sebastian Celis on 5/6/19.
//  Copyright © 2019 BuzzFeed, Inc. All rights reserved.
//

@testable import MockDuck
import XCTest

class CryptoTests: XCTestCase {
    func testWellKnownMD5s() {
        XCTAssertEqual(CryptoUtils.md5("/tmp/foo/bar/baz".data(using: .utf8)!), "bb4a1d8146e894565b7d379d37ce8c2b")
        XCTAssertEqual(CryptoUtils.md5("this;is=a/simple#test?string".data(using: .utf8)!), "5c79aeb290ab5dec79ad63e40bbed002")
    }
}
