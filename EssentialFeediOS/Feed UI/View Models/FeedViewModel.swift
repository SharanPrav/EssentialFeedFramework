import Foundation
import EssentialFeed

final class FeedViewModelExample {
    typealias Observer<T> = (T) -> Void

    private let feedLoader: FeedLoader
    
    init(feedLoader: FeedLoader) {
        self.feedLoader = feedLoader
    }
    
   // var onChange: ((FeedViewModel) -> Void)?
   // var onFeedLoad: (([FeedImage]) -> Void)?

//    private(set) var isLoading: Bool = false {
//        didSet { onChange?(self) }
//    }
    
    var onLoadingStateChange: Observer<Bool>?
    var onFeedLoad: Observer<[FeedImage]>?
    
    func loadFeed() {
        onLoadingStateChange?(true)
        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad?(feed)
            }
            self?.onLoadingStateChange?(false)
        }
    }
}
