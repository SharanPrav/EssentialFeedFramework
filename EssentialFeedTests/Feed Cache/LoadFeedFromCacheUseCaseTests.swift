//
//  LoadFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Saranya Ravi on 01/11/2023.
//

import XCTest
import EssentialFeed

class LoadFeedFromCacheUseCaseTests: XCTestCase {
    func test_init_doesNotSendAnyMessagesCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMesages, [])
    }
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load{ _ in }
        
        XCTAssertEqual(store.receivedMesages, [.retrieve])
    }
    
    func test_load_failsOnLoadRetreivalError() {
        let (sut, store) = makeSUT()
        let retrievalError = anyError()
        
        expect(sut, toCompleteWith: .failure(retrievalError)) {
            store.completeRetreival(with: retrievalError)
        }
    }
    
    func test_load_deliversNoImageOnEmptyCache() {
        let (sut, store) = makeSUT()

        expect(sut, toCompleteWith: .success([])) {
            store.completeRetreivalwithEmptyCache()
        }
    }
    
    func test_load_deliversCachedImageOnLessThanSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: {
            fixedCurrentDate
        })
        
        expect(sut, toCompleteWith: .success(feed.models)) {
            store.completeRetreival(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        }
    }
    
    func test_load_deliversNoCachedImageOnSevenDaysOldCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let lessThanSevenDaysOldTimestamp = fixedCurrentDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: {
            fixedCurrentDate
        })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetreival(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        }
    }
    
    //MARK: - Helpers
    private func makeSUT(currentDate: @escaping() -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeak(instance: store, file: file, line: line)
        trackForMemoryLeak(instance: sut, file: file, line: line)
        
        return(sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void) {
        let exp = expectation(description: "wait for load completion")
        
        sut.load { receivedResult in
            switch (expectedResult, receivedResult) {
            case let (.success(receivedImages), .success(expectedImages)):
                XCTAssertEqual(receivedImages, expectedImages)
            case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
                XCTAssertEqual(receivedError, expectedError)
            default:
                XCTFail("expected \(expectedResult), got \(receivedResult) instead")
            }
            exp.fulfill()
        }
            
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    private func uniqueImage() -> FeedImage {
        return FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())
    }
    
    private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let models = [uniqueImage(), uniqueImage()]
        let local =  models.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
        return(models, local)
    }
    
    private func anyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func anyError() -> NSError {
        return NSError(domain: "any error", code: 0)
    }
}

private extension Date {
    func adding(days: Int) -> Date {
        return Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        return self + seconds
    }
}
