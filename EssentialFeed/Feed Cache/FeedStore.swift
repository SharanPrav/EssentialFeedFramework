//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Saranya Ravi on 29/10/2023.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void

    func deleteCaheFeed(completion: @escaping DeletionCompletion)
    func insert(_ items: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
}
