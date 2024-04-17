//
//  FeedImageDataStore.swift
//  EssentialFeed
//
//  Created by Saranya Ravi on 03/02/2024.
//

import Foundation

public protocol FeedImageDataStore {
    func insert(_ data: Data, for url: URL) throws
    func retrieve(dataForURL url: URL) throws -> Data?
}
