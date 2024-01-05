import UIKit
import EssentialFeed

public final class FeedRefreshViewController: NSObject, FeedLoadingView {
    
    // It is supposed to be private(Set) but removed it because it has to be replaced with fake for testing.
    public lazy var view = loadView()
    //lazy var view = binded(UIRefreshControl())
    //private let viewModel: FeedViewModel
    
    private let loadFeed: () -> Void

    init(loadFeed: @escaping () -> Void) {
        self.loadFeed = loadFeed
    }
        
    @objc func refresh() {
        loadFeed()
    }
    
    func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }
    
    private func loadView() -> UIRefreshControl {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }
}

