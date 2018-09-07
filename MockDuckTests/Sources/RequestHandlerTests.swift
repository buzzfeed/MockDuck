//
//  RequestHandlerTests.swift
//  MockDuckTests
//
//  Created by Peter Walters on 3/19/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

@testable import MockDuck
import XCTest

class RequestHandlerTests: XCTestCase {

    let testURL: URL! = URL(string: "https://www.buzzfeed.com/some-invalid-url")

    override func setUp() {
        super.setUp()
        MockDuck.shouldFallbackToNetwork = false
    }

    override func tearDown() {
        MockDuck.unregisterAllRequestHandlers()
        MockDuck.shouldFallbackToNetwork = true
        super.tearDown()
    }

    func testRequestHandlerStatusCode() {
        let statusCode = 201

        MockDuck.registerRequestHandler { request in
            return try! MockResponse(for: request, statusCode: statusCode)
        }

        let expectation = self.expectation(description: "Mocked network request")
        let task = URLSession.shared.dataTask(with: testURL) { data, response, error in
            let response = response as! HTTPURLResponse
            XCTAssertEqual(response.statusCode, statusCode)
            expectation.fulfill()
        }
        task.resume()

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testRequestHandlerHeader() {
        let headerName = "X-BUZZFEED-TEST"
        let headerValue = "Some Value"

        MockDuck.registerRequestHandler { request in
            return try! MockResponse(for: request, headers: [headerName : headerValue])
        }

        let expectation = self.expectation(description: "Mocked network request")
        let task = URLSession.shared.dataTask(with: testURL) { data, response, error in
            let response = response as! HTTPURLResponse
            XCTAssertEqual(response.headers?[headerName], headerValue)
            expectation.fulfill()
        }
        task.resume()

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testRequestHandlerData() {
        let mockData = Data(bytes: [1, 5, 2, 4])

        MockDuck.registerRequestHandler { request in
            return try! MockResponse(for: request, data: mockData)
        }

        let expectation = self.expectation(description: "Mocked network request")
        let task = URLSession.shared.dataTask(with: testURL) { data, response, error in
            XCTAssertEqual(data, mockData)
            expectation.fulfill()
        }
        task.resume()

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testRequestHandlerJSON() {
        let json: [String: Any] = [
            "a": "value",
            "b": 5,
            "c": true
        ]

        MockDuck.registerRequestHandler { request in
            return try! MockResponse(for: request, json: json)
        }

        let expectation = self.expectation(description: "Mocked network request")
        let task = URLSession.shared.dataTask(with: testURL) { data, response, error in
            let responseJSON = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String: Any]
            XCTAssertEqual(responseJSON["a"] as! String, "value")
            XCTAssertEqual(responseJSON["b"] as! Int, 5)
            XCTAssertEqual(responseJSON["c"] as! Bool, true)
            expectation.fulfill()
        }
        task.resume()

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testRequestHandlerMatching() {
        let statusCode1 = 218
        let statusCode2 = 420
        let url1: URL! = URL(string: "https://www.buzzfeed.com/seven-greatest-things-about-salad")
        let url2: URL! = URL(string: "https://tasty.co/pineapple-pizza-is-amazing")
        let expectation1 = self.expectation(description: "Network request one")
        let expectation2 = self.expectation(description: "Network request two")

        MockDuck.registerRequestHandler { request in
            if request.url?.host == "www.buzzfeed.com" {
                return try! MockResponse(for: request, statusCode: statusCode1)
            } else if request.url?.host == "tasty.co" {
                return try! MockResponse(for: request, statusCode: statusCode2)
            } else {
                return nil
            }
        }

        let task1 = URLSession.shared.dataTask(with: url1) { data, response, error in
            let response = response as! HTTPURLResponse
            XCTAssertEqual(response.statusCode, statusCode1)
            expectation1.fulfill()
        }
        task1.resume()

        let task2 = URLSession.shared.dataTask(with: url2) { data, response, error in
            let response = response as! HTTPURLResponse
            XCTAssertEqual(response.statusCode, statusCode2)
            expectation2.fulfill()
        }
        task2.resume()

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testNotFallingBackToNetwork() {
        MockDuck.shouldFallbackToNetwork = false

        let expectation = self.expectation(description: "Mocked network request")
        let task = URLSession.shared.dataTask(with: testURL) { data, response, error in
            let error = error! as NSError
            XCTAssertEqual(error.domain, NSURLErrorDomain)
            XCTAssertEqual(error.code, NSURLErrorNotConnectedToInternet)
            expectation.fulfill()
        }
        task.resume()

        waitForExpectations(timeout: 2.0, handler: nil)
    }
}
