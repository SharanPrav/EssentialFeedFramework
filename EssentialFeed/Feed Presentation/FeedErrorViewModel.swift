//
//  FeedErrorViewModel.swift
//  EssentialFeed
//
//  Created by Saranya Ravi on 24/01/2024.
//

public struct FeedErrorViewModel {
    public let message: String?

    static var noError: FeedErrorViewModel {
        return FeedErrorViewModel(message: nil)
    }
    
    static func error(message: String) -> FeedErrorViewModel {
        return FeedErrorViewModel(message: message)
    }
}
