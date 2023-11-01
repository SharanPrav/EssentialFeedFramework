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
    typealias retreivalCompletion = (Error?) -> Void

    enum ReceivedMessage: Equatable {
        case deleteCachedFeed
        case insert([LocalFeedImage], Date)
        case retrieve 
    }
    
    private var deletionCompletions = [DeletionCompletion]()
    private var insertionCompletions = [DeletionCompletion]()
    private var retreivalCompletions = [retreivalCompletion]()
    private(set) var receivedMesages = [ReceivedMessage]()
    
    func deleteCaheFeed(completion: @escaping DeletionCompletion) {
        deletionCompletions.append(completion)
        receivedMesages.append(.deleteCachedFeed)
    }
    
    func completeDeletion(with error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionSuccessfully(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        insertionCompletions.append(completion)
        receivedMesages.append(.insert(feed, timestamp))
    }
    
    func completeInsertion(with error: Error, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfully(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
    
    func retrieve(completion: @escaping retreivalCompletion) {
        retreivalCompletions.append(completion)
        receivedMesages.append(.retrieve)
    }
    
    func completeRetreival(with error: Error, at index: Int = 0) {
        retreivalCompletions[index](error)
    }
}
