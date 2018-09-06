//
//  MockURLProtocolTests.swift
//  MockDuckTests
//
//  Created by Sebastian Celis on 9/5/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

@testable import MockDuck
import XCTest

class MockURLProtocolTests: XCTestCase {
    override func tearDown() {
        MockDuck.enabled = true
        super.tearDown()
    }

    func testInvalidSchemeDoesNotInit() {
        MockDuck.enabled = true
        let url: URL! = URL(string: "about:blank")
        let request = URLRequest(url: url)
        XCTAssertFalse(MockURLProtocol.canInit(with: request))
    }

    func testEnablingMockDuckDoesInit() {
        MockDuck.enabled = true
        let url: URL! = URL(string: "https://www.buzzfeed.com")
        let request = URLRequest(url: url)
        XCTAssertTrue(MockURLProtocol.canInit(with: request))
    }

    func testDisablingMockDuckDoesNotInit() {
        MockDuck.enabled = false
        let url: URL! = URL(string: "https://www.buzzfeed.com")
        let request = URLRequest(url: url)
        XCTAssertFalse(MockURLProtocol.canInit(with: request))
    }
}
