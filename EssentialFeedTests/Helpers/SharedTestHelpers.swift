//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Saranya Ravi on 05/11/2023.
//

import Foundation

func anyError() -> NSError {
    return NSError(domain: "any error", code: 0)
}

func anyURL() -> URL {
    return URL(string: "http://any-url.com")!
}
