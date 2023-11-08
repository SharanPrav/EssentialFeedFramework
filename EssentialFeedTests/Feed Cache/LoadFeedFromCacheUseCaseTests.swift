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
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestsCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load{ _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrieve])
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
            store.completeRetreivalWithEmptyCache()
        }
    }
    
    func test_load_deliversCachedImagesOnNonExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: {
            fixedCurrentDate
        })
        
        expect(sut, toCompleteWith: .success(feed.models)) {
            store.completeRetreival(with: feed.local, timestamp: nonExpiredTimestamp)
        }
    }
    
    func test_load_deliversNoImagesOnCacheExpiration() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT(currentDate: {
            fixedCurrentDate
        })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetreival(with: feed.local, timestamp: expirationTimestamp)
        }
    }
    
    func test_load_deliversNoImagesOnExpiredCache() {
        let feed = uniqueImageFeed()
        let fixedCurrentDate = Date()
        let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: {
            fixedCurrentDate
        })
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetreival(with: feed.local, timestamp: expiredTimestamp)
        }
    }
    
    func test_load_deletesCacheOnRetrievalError() {
            let (sut, store) = makeSUT()

            sut.load { _ in }
            store.completeRetreival(with: anyError())

            XCTAssertEqual(store.receivedMessages, [.retrieve])
        }

        func test_load_doesNotDeleteCacheOnEmptyCache() {
            let (sut, store) = makeSUT()

            sut.load { _ in }
            store.completeRetreivalWithEmptyCache()

            XCTAssertEqual(store.receivedMessages, [.retrieve])
        }

        func test_load_doesNotDeleteCacheOnNonExpiredCache() {
            let feed = uniqueImageFeed()
            let fixedCurrentDate = Date()
            let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
            let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

            sut.load { _ in }
            store.completeRetreival(with: feed.local, timestamp: nonExpiredTimestamp)

            XCTAssertEqual(store.receivedMessages, [.retrieve])
        }

        func test_load_deletesCacheOnCacheExpiration() {
            let feed = uniqueImageFeed()
            let fixedCurrentDate = Date()
            let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
            let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

            sut.load { _ in }
            store.completeRetreival(with: feed.local, timestamp: expirationTimestamp)

            XCTAssertEqual(store.receivedMessages, [.retrieve])
        }

        func test_load_deletesCacheOnExpiredCache() {
            let feed = uniqueImageFeed()
            let fixedCurrentDate = Date()
            let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
            let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

            sut.load { _ in }
            store.completeRetreival(with: feed.local, timestamp: expiredTimestamp)

            XCTAssertEqual(store.receivedMessages, [.retrieve])
        }

        func test_load_doesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
            let store = FeedStoreSpy()
            var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

            var receivedResults = [LocalFeedLoader.LoadResult]()
            sut?.load { receivedResults.append($0) }

            sut = nil
            store.completeRetreivalWithEmptyCache()

            XCTAssertTrue(receivedResults.isEmpty)
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
}


