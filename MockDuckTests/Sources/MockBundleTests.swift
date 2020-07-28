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
        let headerFields = [headerName: headerValue]

        let url: URL! = URL(string: "https://www.buzzfeed.com/mother-of-dragons")
        let request = URLRequest(url: url)

        MockDuck.recordingURL = recordingURL

        _ = recordResponse(
            url: url,
            statusCode: statusCode,
            responseData: responseData,
            headerFields: headerFields)
        
        let mockRequestResponse = MockRequestResponse(request: request)
        XCTAssertTrue(MockDuck.mockBundle.loadResponse(for: mockRequestResponse))
        XCTAssertNotNil(mockRequestResponse.response)
        XCTAssertEqual((mockRequestResponse.response as! HTTPURLResponse).statusCode, statusCode)
        XCTAssertEqual(mockRequestResponse.responseData, responseData)
        XCTAssertEqual(mockRequestResponse.response?.headers?[headerName], headerValue)
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
    
    func testGetResponse() {
        let statusCode = 530
        let responseData = Data([1, 2, 3, 4])
        let headerName = "X-BUZZFEED-TEST"
        let headerValue = "AMAZING"
        let headerFields = [headerName: headerValue]
        let url: URL! = URL(string: "https://www.buzzfeed.com/mother-of-dragons")

        MockDuck.loadingURL = loadingURL
        MockDuck.recordingURL = recordingURL
        
        _ = recordResponse(
            url: url,
            statusCode: statusCode,
            responseData: responseData,
            headerFields: headerFields)
        
        let mockRequestResponse = MockDuck.mockBundle.getResponses(for: "www.buzzfeed.com").first!
        
        XCTAssertNotNil(mockRequestResponse.response)
        XCTAssertEqual((mockRequestResponse.response as! HTTPURLResponse).statusCode, statusCode)
        XCTAssertEqual(mockRequestResponse.responseData, responseData)
        XCTAssertEqual(mockRequestResponse.response?.headers?[headerName], headerValue)
    }
    
    func testGetResponseSidecar() {
        let responseData = try! JSONSerialization.data(withJSONObject: ["test": "value"])
        let headerName = "Content-Type"
        let headerValue = "application/json"
        let headerFields = [headerName: headerValue]
        let url: URL! = URL(string: "https://www.buzzfeed.com/mother-of-dragons")

        MockDuck.loadingURL = loadingURL
        MockDuck.recordingURL = recordingURL
        
        _ = recordResponse(
            url: url,
            responseData: responseData,
            headerFields: headerFields)

        let mockRequestResponse = MockDuck.mockBundle.getResponses(for: "www.buzzfeed.com").first!
        
        XCTAssertNotNil(mockRequestResponse.response)
        XCTAssertEqual(mockRequestResponse.responseData, responseData)
        XCTAssertEqual(mockRequestResponse.response?.headers?[headerName], headerValue)
    }
    
    func testGetResponseSimpleURL() {
        let url: URL! = URL(string: "https://www.buzzfeed.com/mother-of-dragons")

        MockDuck.loadingURL = loadingURL
        MockDuck.recordingURL = recordingURL
        
        _ = recordResponse(url: url)
        let mockRequestResponse = MockDuck.mockBundle.getResponses(for: "www.buzzfeed.com").first!
        XCTAssertNotNil(mockRequestResponse.response)
    }
    
    func testGetResponseMultipleURL() {
        let url: URL! = URL(string: "https://www.buzzfeed.com/mother-of-dragons")

        MockDuck.loadingURL = loadingURL
        MockDuck.recordingURL = recordingURL
        
        _ = recordResponse(url: url)
        let mockRequestResponse = MockDuck.mockBundle.getResponses(for: "www.buzzfeed.com").first!
        XCTAssertNotNil(mockRequestResponse.response)
    }
    
    func testGetResponseMissingFIle() {
        let url: URL! = URL(string: "https://www.buzzfeed.com/mother-of-dragons")

        MockDuck.loadingURL = loadingURL
        MockDuck.recordingURL = recordingURL
        
        _ = recordResponse(url: url)
        let mockRequestResponse = MockDuck.mockBundle.getResponses(for: "www.test.com").first
        XCTAssertNil(mockRequestResponse)
    }
    
    func testGetResponseFilterMultipleRequests() {
        MockDuck.loadingURL = loadingURL
        MockDuck.recordingURL = recordingURL
        
        let url1: URL! = URL(string: "https://www.buzzfeed.com/mother-of-dragons")
        let url2: URL! = URL(string: "https://www.hodor.com/hodor")
        _ = recordResponse(url: url1)
        _ = recordResponse(url: url2)

        let count = MockDuck.mockBundle.getResponses(for: "www.hodor.com").count
        XCTAssertEqual(count, 1)
    }

    func testGetResponseMultipleRequests() {
        MockDuck.loadingURL = loadingURL
        MockDuck.recordingURL = recordingURL
        
        let url1: URL! = URL(string: "https://www.buzzfeed.com/mother-of-dragons")
        let url2: URL! = URL(string: "https://www.buzzfeed.com/hodor")
        _ = recordResponse(url: url1)
        _ = recordResponse(url: url2)

        let count = MockDuck.mockBundle.getResponses(for: "www.buzzfeed.com").count
        XCTAssertEqual(count, 2)
    }
    
    func testRelativeURL1() {
        let url1: URL! = URL(string: "https://www.buzzfeed.com/mother/of/dragons")
        let url2: URL! = URL(string: "https://www.buzzfeed.com/")

        let result = url1.pathRelative(to: url2)
        XCTAssertEqual("mother/of/dragons", result)
    }
    
    func testRelativeURL2() {
        let url1: URL! = URL(string: "https://www.buzzfeed.com/mother/of/dragons")
        let url2: URL! = URL(string: "https://www.buzzfeed.com/mother/of")

        let result = url1.pathRelative(to: url2)
        XCTAssertEqual("dragons", result)
    }
    
    func testRelativeURL3() {
        let url1: URL! = URL(string: "https://www.buzzfeed.com")
        let url2: URL! = URL(string: "https://www.buzzfeed.com/mother/of")

        let result = url1.pathRelative(to: url2)
        XCTAssertNil(result)
    }

    func testRelativeURL4() {
        let url1: URL! = URL(string: "https://www.buzzfeed.com/mother/of/dragons")
        let url2: URL! = URL(string: "https://www.hodor.com/")

        let result = url1.pathRelative(to: url2)
        XCTAssertNil(result)
    }
    
    func testRelativeURL5() {
        let url1: URL! = URL(string: "file:///a/b/c/d/e/f")
        let url2: URL! = URL(string: "file://a/b/c/")

        let result = url1.pathRelative(to: url2)
        XCTAssertNil(result)
    }

    // MARK: - Utilities

    func recordResponse(
        url: URL,
        statusCode: Int = 200,
        responseData: Data? = nil,
        headerFields: [String: String]? = nil) -> MockRequestResponse
    {
        let request = URLRequest(url: url)
        
        let response: HTTPURLResponse! = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: headerFields)
        let mockResponse = MockResponse(
            response: response,
            responseData: responseData)
        let requestResponse = MockRequestResponse(
            request: request,
            mockResponse: mockResponse)
        MockDuck.mockBundle.record(requestResponse: requestResponse)
        return requestResponse
    }
}
