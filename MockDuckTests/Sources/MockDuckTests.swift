//
//  MockDuckTests.swift
//  MockDuckTests
//
//  Created by Sebastian Celis on 9/10/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

import Foundation
@testable import MockDuck
import XCTest

class MockDuckTests: XCTestCase {
    func testURLProtocolIsInjected() {
        MockDuck.enabled = true
        let defaultConfig = URLSessionConfiguration.default
        XCTAssertTrue(defaultConfig.protocolClasses?.contains { $0 == MockURLProtocol.self } == true)
        let ephemeralConfig = URLSessionConfiguration.default
        XCTAssertTrue(ephemeralConfig.protocolClasses?.contains { $0 == MockURLProtocol.self } == true)
    }
}
