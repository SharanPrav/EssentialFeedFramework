//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Saranya Ravi on 08/10/2023.
//

import XCTest
import EssentialFeed

class URLSessionHTTPClientTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        print("called teardown")
        URLProtocolStub.removeStub()
    }
    
    func test_getFromURL_performGETRequestWithURL() {
        let url = anyURL()
        let exp = expectation(description: "wait for request")

        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    
    func test_getFromURL_failsOnRequestError() {
        let requestError = anyError()
        let receivedError = resultErrorFor((data: nil, response: nil, error: requestError))
                
        XCTAssertEqual((receivedError as NSError?)?.domain, requestError.domain)
        XCTAssertEqual((receivedError as NSError?)?.code, requestError.code)
    }
    
    func test_getFromURL_failsOnAllInvalidCases() {
        XCTAssertNotNil(resultErrorFor((data: nil, response: nil, error: nil)))
        XCTAssertNotNil(resultErrorFor((data: nil, response: nonHTTPURLResponse(), error: nil)))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nil, error: nil)))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nil, error: anyError())))
        XCTAssertNotNil(resultErrorFor((data: nil, response: nonHTTPURLResponse(), error: anyError())))
        XCTAssertNotNil(resultErrorFor((data: nil, response: anyHTTPURLResponse(), error: anyError())))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nonHTTPURLResponse(), error: anyError())))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: anyHTTPURLResponse(), error: anyError())))
        XCTAssertNotNil(resultErrorFor((data: anyData(), response: nonHTTPURLResponse(), error: nil)))
    }

    func test_getFromURL_succeedsOnHTTPURLResponseWithData() {
        let data = anyData()
        let response = anyHTTPURLResponse()
        let receivedValues = resultValuesFor((data: data, response: response, error: nil))

        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    func test_getFromURL_succeedsWithEmptyDataOnHTTPURLResponseWithNilData() {
        let emptyData = Data()
        let response = anyHTTPURLResponse()
        let receivedValues = resultValuesFor((data: nil, response: response, error: nil))
        
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    func test_cancelGetFromURLTask_cancelsURLRequest() {
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequests { _ in exp.fulfill() }
        
        let receivedError = resultErrorFor(taskHandler: { $0.cancel() }) as NSError?
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(receivedError?.code, URLError.cancelled.rawValue)
    }
    
    // MARK: helpers
    
    func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        
        let sut = URLSessionHTTPClient(session: session)
        trackForMemoryLeak(instance: sut, file: file, line: line)
        return sut
    }
    
    private func resultErrorFor(_ values: (data: Data?, response: URLResponse?, error: Error?)? = nil, taskHandler: (HTTPClientTask) -> Void = { _ in }, file: StaticString = #file, line: UInt = #line) -> Error? {
        let result = resultFor(values, taskHandler: taskHandler, file: file, line: line)
        
        switch result {
        case let .failure(error):
            return error
        default:
            XCTFail("expected failure, got \(result) instead", file: file, line: line)
            return nil
        }
    }
    
    private func resultValuesFor(_ values: (data: Data?, response: URLResponse?, error: Error?), file: StaticString = #file, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(values, file: file, line: line)

        switch result {
        case let .success((data, response)):
            return (data, response)
        default:
            XCTFail("expected success, got \(result) instead", file: file, line: line)
            return nil
        }
           
    }
    
    private func resultFor(_ values: (data: Data?, response: URLResponse?, error: Error?)?, taskHandler: (HTTPClientTask) -> Void = { _ in },  file: StaticString = #file, line: UInt = #line) -> HTTPClient.Result {
        values.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }
        
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "wai for completion")
        
        var receivedResult: HTTPClient.Result!
        taskHandler(sut.get(from: anyURL()) { result in
            receivedResult = result
            exp.fulfill()
        })
        
        wait(for: [exp], timeout: 1.0)
        return receivedResult
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func anyData() -> Data {
        return Data("any data".utf8)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func anyError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}
