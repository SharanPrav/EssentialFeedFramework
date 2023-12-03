//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Saranya Ravi on 01/11/2023.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetreivalCompletion = (RetrievalResult) -> Void

    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve 
    }
    
    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [DeletionCompletion]()
    private var retreivalCompletions = [RetreivalCompletion]()
    private(set) var receivedMessages = [ReceivedMessage]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMessages.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMessages.append(.insert(feed, timestamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func retrieve(completion: @escaping RetreivalCompletion) {
        retreivalCompletions.append(completion)
        receivedMessages.append(.retrieve)
    }
    
    func completeRetreival(with error: Error, at index: Int = 0) {
        retreivalCompletions[index](.failure(error))
    }
    
    func completeRetreival(with feed: [LocalFeedImage], timestamp: Date, at index: Int = 0) {
        retreivalCompletions[index](.success(.found(feed: feed, timestamp: timestamp)))
    }
    
    func completeRetreivalWithEmptyCache(at index: Int = 0) {
        retreivalCompletions[index](.success(.empty))
    }
}
