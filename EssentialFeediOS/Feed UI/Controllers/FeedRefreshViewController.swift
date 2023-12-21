import UIKit
import EssentialFeed

final class FeedViewModel {
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

final class FeedRefreshViewController: NSObject {
    
    // It is supposed to be private(Set) but removed it because it has to be replaced with fake for testing. 
    lazy var view = binded(UIRefreshControl())
    
    private let viewModel: FeedViewModel

    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }
        
    @objc func refresh() {
        viewModel.loadFeed()
    }
    
    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onLoadingStateChange = { [weak self] isLoading in
            if isLoading {
                self?.view.beginRefreshing()
            } else {
                self?.view.endRefreshing()
            }
        }
        
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}

