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
    
    //MARK: - Helpers
    private func makeSUT(currentDate: @escaping() -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeak(instance: store, file: file, line: line)
        trackForMemoryLeak(instance: sut, file: file, line: line)
        
        return(sut, store)
    }
}
