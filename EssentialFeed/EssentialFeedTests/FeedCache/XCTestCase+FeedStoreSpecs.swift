//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Jacob Rakidzich on 10/19/23.
//

import EssentialFeed
import Foundation
import XCTest

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    
    func assertThatDeleteDeliversErrorOnDeletionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {

        XCTAssertNotNil(deleteCache(from: sut), "Expected cache deletion to fail")
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatDeleteHasNoSideEffectsOnDeletionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        
        deleteCache(from: sut)
        
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
}

extension FailableInsertFeedStoreSpecs where Self: XCTestCase {
    
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = uniqueImages().local
        let timestamp = Date()

        let insertionError = insert((feed, timestamp), to: sut)

        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error")
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = uniqueImages().local
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)
        
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
}

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    func assertThatRetrieveDeliversFailureOnRetrievalError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
            expect(sut, toRetrieve: .failure(EquatableError()), file: file, line: line)
        }

        func assertThatRetrieveHasNoSideEffectsOnFailure(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
            expect(sut, toRetrieveTwice: .failure(EquatableError()), file: file, line: line)
        }
}

extension FeedStoreSpecs where Self: XCTestCase {
    
    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .empty)
    }
    
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = uniqueImages().local
        let timestamp = Date()
        
        insert((feed, timestamp), to: sut)

        expect(sut, toRetrieveTwice: .found(images: feed, timestamp: timestamp), file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = uniqueImages().local
        let timestamp = Date()

        insert((feed, timestamp), to: sut)

        expect(sut, toRetrieve: .found(images: feed, timestamp: timestamp), file: file, line: line)
    }
    
    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNil(
            insert((uniqueImages().local, Date()), to: sut),
            "Expected to insert cache successfully"
        )
    }
    
    func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueImages().local, Date()), to: sut)
        
        XCTAssertNil(
            insert((uniqueImages().local, Date()), to: sut),
            "Expected to override cache successfully"
        )
    }
    
    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueImages().local, Date()), to: sut)
        
        let latestFeed = uniqueImages().local
        let latestTimestamp = Date()
        
        insert((latestFeed, latestTimestamp), to: sut)
        expect(sut, toRetrieve: .found(images: latestFeed, timestamp: latestTimestamp), file: file, line: line)
    }
    
    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        XCTAssertNil(
            deleteCache(from: sut),
            "Expected empty cache deletion to succeed"
        )
    }
    
    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        
        deleteCache(from: sut)
        
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueImages().local, Date()), to: sut)
        
        XCTAssertNil(
            deleteCache(from: sut),
            "Expected non-empty cache deletion to succeed"
        )
    }
    
    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert((uniqueImages().local, Date()), to: sut)
        
        deleteCache(from: sut)
        
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
   
    func assertThatSideEffectsRunSerially(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        var completedOperationsInOrder = [XCTestExpectation]()
        
        let operation = expectation(description: "Operation 1")
        sut.insert(uniqueImages().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(operation)
            operation.fulfill()
        }
        
        let operation2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(operation2)
            operation2.fulfill()
        }
        
        let operation3 = expectation(description: "Operation 3")
        sut.insert(uniqueImages().local, timestamp: Date()) { _ in
            completedOperationsInOrder.append(operation3)
            operation3.fulfill()
        }
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(completedOperationsInOrder, [operation, operation2, operation3], "Expected to run serially but finished in the wrong order")
    }
}

extension FeedStoreSpecs where Self: XCTestCase {
    
    func expect(
        _ sut: FeedStore,
        toRetrieve expectedResult: LocalFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for cache retrieval")
        
        sut.retrieve { retrievedResult in
            switch (expectedResult, retrievedResult) {
            case (.empty, .empty), (.failure, .failure):
                break
                
            case let (.found(expectedFeed, expectedTimestamp), .found(retrievedFeed, retrievedTimestamp)):
                XCTAssertEqual(retrievedFeed, expectedFeed, file: file, line: line)
                XCTAssertEqual(retrievedTimestamp, expectedTimestamp, file: file, line: line)
                
            default:
                XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
            }
            
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func expect(
        _ sut: FeedStore,
        toRetrieveTwice expectedResult: LocalFeedResult,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    @discardableResult
    func insert(
        _ cache: (feed: [LocalFeedImage], timestamp: Date),
        to sut: FeedStore,
        file: StaticString = #file,
        line: UInt = #line
    ) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var error: Error?
        sut.insert(cache.feed, timestamp: cache.timestamp) { insertionError in
            error = insertionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return error
    }
    
    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
}
