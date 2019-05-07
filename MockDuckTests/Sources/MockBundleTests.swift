//
//  MockBundleTests.swift
//  MockDuckTests
//
//  Created by Sebastian Celis on 9/5/18.
//  Copyright © 2018 BuzzFeed, Inc. All rights reserved.
//

@testable import MockDuck
import XCTest

class MockBundleTests: XCTestCase {
    var loadingURL: URL!
    var recordingURL: URL!

    override func setUp() {
        super.setUp()

        let filePath = String(describing: #file)
        let fileURL = URL(fileURLWithPath: filePath)
        let bundleURL = fileURL
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources")
            .appendingPathComponent("TestBundle")

        MockDuck.shouldFallbackToNetwork = false
        loadingURL = bundleURL
        recordingURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("MockBundleTests")
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: recordingURL)
        MockDuck.loadingURL = nil
        MockDuck.recordingURL = nil
        super.tearDown()
    }

    func testBasicRecordThenRead() {
        let statusCode = 530
        let responseData = Data([1, 2, 3, 4])
        let headerName = "X-BUZZFEED-TEST"
        let headerValue = "AMAZING"

        let url: URL! = URL(string: "https://www.buzzfeed.com/mother-of-dragons")
        let request = URLRequest(url: url)
        let response: HTTPURLResponse! = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: [headerName: headerValue])
        let mockResponse = MockResponse(response: response, responseData: responseData)
        let requestResponse = MockRequestResponse(request: request, mockResponse: mockResponse)
        MockDuck.recordingURL = recordingURL
        MockDuck.mockBundle.record(requestResponse: requestResponse)
        let loadedRequestResponse: MockRequestResponse! = MockDuck.mockBundle.loadRequestResponse(for: request)
        XCTAssertNotNil(loadedRequestResponse)
        XCTAssertEqual((loadedRequestResponse.response as! HTTPURLResponse).statusCode, statusCode)
        XCTAssertEqual(loadedRequestResponse.responseData, responseData)
        XCTAssertEqual(loadedRequestResponse.response.headers?[headerName], headerValue)
    }

    func testLoadBundleBasic() {
        MockDuck.loadingURL = loadingURL

        let taskExpectation = expectation(description: "url task")
        let url: URL! = URL(string: "https://www.buzzfeed.com/mother-of-dragons")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            XCTAssertEqual(data?.count ?? 0, 0)
            XCTAssertNil(error)
            XCTAssertEqual((response as! HTTPURLResponse).statusCode, 207)
            XCTAssertEqual((response as! HTTPURLResponse).allHeaderFields["X-YOU-KNOW-NOTHING"] as! String, "Jon Snow")
            taskExpectation.fulfill()
        }
        task.resume()

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testLoadBundleData() {
        MockDuck.loadingURL = loadingURL

        let taskExpectation = expectation(description: "url task")
        let url: URL! = URL(string: "https://www.buzzfeed.com/hodor")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            XCTAssertNil(error)
            XCTAssertNotNil(response)
            let dataString = String(data: data!, encoding: .utf8)!
            XCTAssertEqual(dataString, "Hodor hodor hodor hodor")
            taskExpectation.fulfill()
        }
        task.resume()

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testLoadBundleJSON() {
        MockDuck.loadingURL = loadingURL

        let taskExpectation = expectation(description: "url task")
        let url: URL! = URL(string: "https://www.buzzfeed.com/septa-unella")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            XCTAssertNil(error)
            XCTAssertNotNil(response)
            let responseJSON = try! JSONSerialization.jsonObject(with: data!, options: []) as! [String]
            XCTAssertEqual(["shame", "shame", "shame", "DING"], responseJSON)
            taskExpectation.fulfill()
        }
        task.resume()

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testLoadBundleImage() {
        MockDuck.loadingURL = loadingURL

        let taskExpectation = expectation(description: "image download")
        let url: URL! = URL(string: "https://www.buzzfeed.com/logo.png")
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            XCTAssertNil(error)
            XCTAssertNotNil(response)
            XCTAssertGreaterThan(data?.count ?? 0, 10)
            taskExpectation.fulfill()
        }
        task.resume()

        waitForExpectations(timeout: 2.0, handler: nil)
    }
}
