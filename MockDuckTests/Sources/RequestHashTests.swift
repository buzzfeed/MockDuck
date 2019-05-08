//
//  RequestHashTests.swift
//  MockDuckTests
//
//  Created by Sebastian Celis on 9/5/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

@testable import MockDuck
import XCTest

class RequestHashTests: XCTestCase {
    override func tearDown() {
        MockDuck.delegate = nil
        super.tearDown()
    }

    func testSameRequestSameHash() {
        let url1: URL! = URL(string: "https://www.buzzfeed.com/so-many-tests?foo=bar")
        let url2: URL! = URL(string: "https://www.buzzfeed.com/so-many-tests?foo=bar")
        let request1 = URLRequest(url: url1)
        let request2 = URLRequest(url: url2)
        XCTAssertEqual(request1.requestHash, request2.requestHash)
    }

    func testDifferentQueryDifferentHash() {
        let url1: URL! = URL(string: "https://www.buzzfeed.com/so-many-tests?foo=bar")
        let url2: URL! = URL(string: "https://www.buzzfeed.com/so-many-tests?foo=baz")
        let request1 = URLRequest(url: url1)
        let request2 = URLRequest(url: url2)
        XCTAssertNotEqual(request1.requestHash, request2.requestHash)
    }

    func testDifferentFragmentDifferentHash() {
        let url1: URL! = URL(string: "https://www.buzzfeed.com/so-many-tests#utm_term=ugh")
        let url2: URL! = URL(string: "https://www.buzzfeed.com/so-many-tests#utm_term=ouch")
        let request1 = URLRequest(url: url1)
        let request2 = URLRequest(url: url2)
        XCTAssertNotEqual(request1.requestHash, request2.requestHash)
    }

    func testDifferentBodyDifferentHash() {
        let url: URL! = URL(string: "https://www.buzzfeed.com/so-many-tests")
        var request1 = URLRequest(url: url)
        var request2 = URLRequest(url: url)
        request1.httpBody = Data([1, 2, 3, 4])
        request2.httpBody = Data([1, 2, 3, 6])
        XCTAssertNotEqual(request1.requestHash, request2.requestHash)
    }

    func testNormalizedRequestsSameHash() {
        class TestMockDuckDelegate: MockDuckDelegate {
            func normalizedRequest(for request: URLRequest) -> URLRequest {
                var request = request
                request.httpBody = nil

                if
                    let url = request.url,
                    var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
                {
                    components.fragment = nil
                    components.queryItems = nil
                    request.url = components.url
                }

                return request
            }
        }
        
        let testDelegate = TestMockDuckDelegate()
        MockDuck.delegate = testDelegate

        let url1: URL! = URL(string: "https://www.buzzfeed.com/so-many-tests?foo=bar#utm_term=ugh")
        let url2: URL! = URL(string: "https://www.buzzfeed.com/so-many-tests?foo=baz#utm_term=ouch")
        var request1 = URLRequest(url: url1)
        var request2 = URLRequest(url: url2)
        request1.httpBody = Data([1, 2, 3, 4])
        request2.httpBody = Data([4, 3, 2, 1])
        XCTAssertEqual(request1.requestHash, request2.requestHash)
    }
}
