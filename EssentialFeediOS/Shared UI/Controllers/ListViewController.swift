import UIKit
import EssentialFeed

public final class ListViewController: UITableViewController, UITableViewDataSourcePrefetching, ResourceLoadingView, ResourceErrorView {
    
    private(set) public var errorView = ErrorView()

    private var loadingControllers = [IndexPath: CellController]()

    private var tableModel = [CellController]() {
        didSet { tableView.reloadData() }
    }
    private var cellControllers = [IndexPath: CellController]()

    private var onViewIsAppearing: ((ListViewController) -> Void)?
    
    public var onRefresh: (() -> Void)?

    public override func viewDidLoad() {
        super.viewDidLoad()
        
        configureErrorView()
        
        onViewIsAppearing = { vc in
            vc.onViewIsAppearing = nil
            vc.refresh()
        }
    }
    
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        tableView.sizeTableHeaderToFit()
    }
    
    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    private func configureErrorView() {
        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(errorView)
        
        errorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: errorView.trailingAnchor),
            errorView.topAnchor.constraint(equalTo: container.topAnchor),
            container.bottomAnchor.constraint(equalTo: errorView.bottomAnchor),
        ])
        
        tableView.tableHeaderView = container
        
        errorView.onHide = { [weak self] in
            self?.tableView.beginUpdates()
            self?.tableView.sizeTableHeaderToFit()
            self?.tableView.endUpdates()
        }
    }
    
    public func display(_ cellControllers: [CellController]) {
        tableModel = cellControllers
    }
    
    public func display(_ viewModel: ResourceLoadingViewModel) {
        loadingControllers = [:]
        refreshControl?.update(isRefreshing: viewModel.isLoading)
    }
    
    public func display(_ viewModel: ResourceErrorViewModel) {
        errorView.message = viewModel.message
    }
    
    @IBAction private func refresh() {
        onRefresh?()
    }
    
    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }
    
    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ds = cellController(forRowAt: indexPath).dataSource
        return ds.tableView(tableView, cellForRowAt: indexPath)
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let dl = removeLoadingController(forRowAt: indexPath)?.delegate
        dl?.tableView?(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }
    
    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        //startTask(forRowAt: indexPath)
    }
    
    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let dsp = removeLoadingController(forRowAt: indexPath)?.dataSourcePrefetching
            dsp?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
        }
    }
    
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let dsp = cellController(forRowAt: indexPath).dataSourcePrefetching
            dsp?.tableView(tableView, prefetchRowsAt: [indexPath])
        }
    }
    
    private func cellController(forRowAt indexPath: IndexPath) -> CellController {
        let controller = tableModel[indexPath.row]
        loadingControllers[indexPath] = controller
        return controller
    }
    
    private func removeLoadingController(forRowAt indexPath: IndexPath) -> CellController? {
        let controller = loadingControllers[indexPath]
        loadingControllers[indexPath] = nil
        return controller
    }
}
