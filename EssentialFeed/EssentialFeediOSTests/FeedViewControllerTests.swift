//
//  FeedViewControllerTests.swift
//  EssentialFeediOSTests
//
//  Created by Jacob Rakidzich on 10/22/23.
//

import XCTest
import UIKit
import EssentialFeed

final class FeedViewController: UITableViewController {
    private var loader: FeedLoader?
    
    private var hasAppeared = false
    
    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        guard hasAppeared else {
            hasAppeared = true
            load()
            return
        }
    }
    
    @objc private func load() {
        refreshControl?.beginRefreshing()

        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}

final class FeedViewControllerTests: XCTestCase {
    
    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_viewDidLoad_loadsFeed() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    func test_pullToRefresh_loadsFeed() {
        let (sut, loader) = makeSUT()

        sut.simulateAppearance()
        XCTAssertEqual(loader.loadCallCount, 1)
        
        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallCount, 2)
        
        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallCount, 3)
    }
    
    func test_viewIsAppearing_showsLoadingIndicator() {
        let (sut, _) = makeSUT()

        sut.simulateAppearance()

        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)
    }

    func test_viewDidLoad_hidesLoadingIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeSUT()
        
        sut.simulateAppearance()
        loader.completeFeedLoading()
        
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> (sut: FeedViewController, loader: LoaderSpy) {
        let loader = createAndTrackMemoryLeaks(LoaderSpy())
        let sut = createAndTrackMemoryLeaks(FeedViewController(loader: loader))
        return (sut, loader)
    }
    
    class LoaderSpy: FeedLoader {
        var loadCallCount: Int {
            completions.count
        }

        private var completions = [(FeedLoader.Result) -> Void]()

        func load(completion: @escaping (FeedLoader.Result) -> Void) {
            completions.append(completion)
        }
        
        func completeFeedLoading(with images: [FeedImage] = [], at index: Int = 0) {
            completions[index](.success(images))
        }
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
