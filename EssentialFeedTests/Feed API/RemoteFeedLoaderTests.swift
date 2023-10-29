import XCTest
@testable import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSut()
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "http://aurl.com")!
        let (sut, client) = makeSut(url: url)
        sut.load { _ in }
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadtwice_requestDataFromURLTwice() {
        let url = URL(string: "http://aurl.com")!
        let (sut, client) = makeSut(url: url)
        sut.load { _ in }
        sut.load { _ in }

        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_loadDeliversErrorOnClientError() {
        let (sut, client) = makeSut()
        
        expect(sut, toCompleteWithError: failure(.connectivity), when: {
            let clientError = NSError(domain: "Test", code: 0)
            client.complete(with: clientError)
        })
    }
    
    func test_loadDataDeviversInvalidDataError() {
        let (sut, client) = makeSut()
        
        let sampleErrorCodes = [199, 201, 300, 400, 500]
        
        sampleErrorCodes.enumerated().forEach { index, code in
            expect(sut, toCompleteWithError: failure(.invalidData), when: {
                let json = makeItemJson([])
                client.complete(withStatusCode: code, data: json,at: index)
            })
        }
    }
    
    func test_loadDeliversErrorOn200HttpResponseWithInvalidJson() {
        let (sut, client) = makeSut()

        expect(sut, toCompleteWithError: failure(.invalidData), when: {
            let invalidJSON = Data("invalid json".utf8)
            client.complete(withStatusCode: 200, data: invalidJSON)
        })
    }
    
    func test_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        let (sut, client) = makeSut()
        
        expect(sut, toCompleteWithError: failure(.invalidData), when: {
            let emptyListJSON = Data("{\"Items\": []}".utf8)
            client.complete(withStatusCode: 200, data: emptyListJSON)
        })
    }
    
    func test_load_deliverysItemsOn200HTTPResponseWithJsonItems() {
        let (sut,client) = makeSut()
        

        let item1 = makeItem(id: UUID(), imageURL: URL(string: "http://aurl.com")!)
        
        let item2 = makeItem(id: UUID(),
                             description: "a description",
                             location: "a location",
                             imageURL: URL(string: "http://another-url.com")!)
      
        expect(sut, toCompleteWithError: .success([item1.model, item2.model])) {
            let json = makeItemJson([item1.json, item2.json])
            client.complete(withStatusCode: 200, data: json)
        }
    }
    
    func test_load_shouldNotDeliverResultWhenClientIsDeallocated() {
        let url = URL(string: "http://aurl.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
        
        var capturedResults = [RemoteFeedLoader.Result]()
        sut?.load { capturedResults.append( $0)}
        
        sut = nil
        client.complete(withStatusCode: 200, data: makeItemJson([]))
        
        XCTAssertTrue(capturedResults.isEmpty)
    }
    
    // MARK: Helpers
    
    private func makeItemJson(_ items: [[String: Any]]) -> Data {
        let json = ["items": items]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedImage, json: [String: Any]) {
        let item = FeedImage(id: id, description: description, location: location, url: imageURL)
        
        let json = ["id": id.uuidString,
                    "description": description,
                    "location": location,
                    "image": imageURL.absoluteString ].compactMapValues { $0 }
        
        return(item, json)
    }
    
    private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
        return .failure(error)
    }
    
    private func expect(_ sut: RemoteFeedLoader, toCompleteWithError expectedResult: RemoteFeedLoader.Result, when action: ()-> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "wait for load completion")
        
        sut.load { receivedResult in
            switch(receivedResult, expectedResult) {
            case let(.success(recivedItems), .success(expectedItems)):
                XCTAssertEqual(recivedItems, expectedItems, file: file, line: line)
            case let(.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
                XCTAssertEqual(receivedError, expectedError, file: file, line: line)
            default:
                XCTFail("Expected result \(expectedResult) but got \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        
        wait(for: [exp], timeout: 1.0)
    }
    
    private func makeSut(url: URL = URL(string: "http://aurl.com")!, file: StaticString = #filePath, line: UInt = #line) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        trackForMemoryLeak(instance: sut, file: file, line: line)
        trackForMemoryLeak(instance: client, file: file, line: line)
        return (sut, client)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] {
            return messages.map { $0.url }
        }
                 
        private var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data, at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}
