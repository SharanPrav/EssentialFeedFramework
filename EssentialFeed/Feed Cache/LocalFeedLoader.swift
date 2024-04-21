//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Saranya Ravi on 29/10/2023.
//

import Foundation

public final class LocalFeedLoader {
    private let store: FeedStore
    private let currentDate: () -> Date
        
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalFeedLoader: FeedCache {
    public typealias SaveResult = FeedCache.Result

    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        completion(SaveResult {
            try store.deleteCachedFeed()
            try store.insert(feed.toLocal(), timestamp: currentDate())
        })
    }
}
    

extension LocalFeedLoader {
    public typealias LoadFeedResult = Swift.Result<[FeedImage], Error>

    public func load(completion: @escaping (LoadFeedResult)-> Void) {
        completion(LoadFeedResult {
            if let cache = try store.retrieve(), FeedCachePolicy.validate(cache.timestamp, against: self.currentDate()) {
                return cache.feed.toModels()
            }
            return []
        })
    }
}

extension LocalFeedLoader {
    public typealias ValidationResult = Result<Void, Error>
    
    private struct InvalidCache: Error {}

    public func validateCache(completion: @escaping (ValidationResult) -> Void) {
        completion(ValidationResult {
            do {
                if let cache = try store.retrieve(), !FeedCachePolicy.validate(cache.timestamp, against: currentDate()) {
                    throw InvalidCache()
                }
            } catch {
                try store.deleteCachedFeed()
            }
        })
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        return map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}

private extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        return map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    }
}
