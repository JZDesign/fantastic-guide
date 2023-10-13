//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Jacob Rakidzich on 10/12/23.
//

import XCTest
import EssentialFeed

class HTTPClientSpy: HTTPClient {
    var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
    var requestedURLs: [URL] {
        messages.map(\.url)
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        messages.append((url, completion))
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(with statusCode: Int, data: Data = .init(), at index: Int = 0) {
        let response = HTTPURLResponse(url: requestedURLs[index], statusCode: statusCode, httpVersion: nil, headerFields: .none)!
        messages[index].completion(.success((response, data)))
    }
}

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.requestedURLs, [])
    }
    
    func test_load_requestsDataFromURL() {
        let (sut, client) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [URL(string: "http://test.com")!])
    }
    
    func test_load_requestsDataFromURLTwice() {
        let (sut, client) = makeSUT()
        let url = URL(string: "http://test.com")!
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.connectivity)) {
            client.complete(with: NSError())
        }
    }
    
    func test_load_deliversErrorOnNon200HttpResponse() {
        [199, 201, 400, 500].forEach { statusCode in
            let (sut, client) = makeSUT()
            expect(sut, toCompleteWith: .failure(.invalidData)) {
                client.complete(with: statusCode)
            }
        }
    }
    
    func test_load_deliversErrorOn200WithInvalidJSON() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .failure(.invalidData)) {
            client.complete(with: 200, data: "invalid".data(using: .utf8)!)
        }
    }
    
    func test_load_deliversNoItemsOn200WithEmptyJSONList() {
        let (sut, client) = makeSUT()
        
        expect(sut, toCompleteWith: .success([])) {
            client.complete(with: 200, data: #"{"items": []}"#.data(using: .utf8)!)
        }
    }
    
    
    func test_load_deliversItemsOn200WithJSONList() {
        let (sut, client) = makeSUT()
        let item1 = makeItem(description: "1", location: "1", imageURL: URL(string: "http://test1.com")!)
        let item2 = makeItem(description: "2", location: "2", imageURL: URL(string: "http://test2.com")!)
        
        let jsonObject = ["items": [ item1.json, item2.json ]]
        
        expect(sut, toCompleteWith: .success([item1.item, item2.item])) {
            client.complete(with: 200, data: try! JSONSerialization.data(withJSONObject: jsonObject))
        }
    }
    
    // MARK: - Helpers
    
    func makeItem(id: UUID = .init(), description: String? = nil, location: String? = nil, imageURL: URL) -> (item: FeedItem, json: [String : Encodable]) {
        let item = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        return (item, jsonItem(for: item))
    }
    
    func jsonItem(for item: FeedItem) -> [String : Encodable] {
        [
            "id": item.id.uuidString,
            "description": item.description,
            "location": item.location,
            "image": item.imageURL.absoluteString
        ]
    }
    
    func expect(
        _ sut: RemoteFeedLoader,
        toCompleteWith result: RemoteFeedLoaderResult,
        file: StaticString = #file,
        line: UInt = #line,
        when action: () -> Void
    ) {
        var results = [RemoteFeedLoaderResult]()
        
        sut.load { result in results.append(result) }
        action()
        
        XCTAssertEqual(results, [result], file: file, line: line)
    }
    
    func makeSUT(url: URL = URL(string: "http://test.com")!) -> (RemoteFeedLoader, HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
}
