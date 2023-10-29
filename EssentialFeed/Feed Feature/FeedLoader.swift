//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Saranya Ravi on 23/09/2023.
//

import Foundation

public enum  LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
