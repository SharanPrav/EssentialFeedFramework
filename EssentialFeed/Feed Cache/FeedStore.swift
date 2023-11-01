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
    typealias retreivalCompletion = (Error?) -> Void

    func deleteCaheFeed(completion: @escaping DeletionCompletion)
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping retreivalCompletion)
}
