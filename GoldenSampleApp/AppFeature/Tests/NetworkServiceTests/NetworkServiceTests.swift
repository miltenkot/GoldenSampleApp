import Testing
@preconcurrency import Foundation
@testable import NetworkService

@MainActor
@Suite("Network Service Tests", .serialized)
final class NetworkServiceTests {
    
    // MARK: - Local Mock Data Models
    
    struct MockPost: Codable, Equatable, CustomStringConvertible {
        let userId: Int
        let id: Int
        let title: String
        let body: String
        
        var description: String {
            "MockPost(id: \(id), title: \"\(title)\")"
        }
    }
    
    struct MockComment: Codable, Equatable, CustomStringConvertible {
        let id: Int
        let name: String
        let email: String
        let body: String
        
        var description: String {
            "MockComment(id: \(id), name: \"\(name)\")"
        }
    }
    
    struct MockPhotoPayload: Codable, Equatable, CustomStringConvertible {
        let albumId: Int
        let id: String
        let title: String
        let url: String
        let thumbnailUrl: String
        
        var description: String {
            "MockPhotoPayload(id: \(id), title: \"\(title)\")"
        }
    }
    
    struct MockEmptyPayload: Codable, Equatable, CustomStringConvertible {
        var description: String { "MockEmptyPayload()" }
    }
    
    // MARK: - Test Setup
    
    let mockPhotoPayload = MockPhotoPayload(albumId: 1, id: "1", title: "Mock Photo Title", url: "mockurl.com", thumbnailUrl: "mockthumbnail.com")
    let mockEmptyPayload = MockEmptyPayload()
    
    var sut: NetworkService!
    var urlSession: URLSession!
    
    init() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        urlSession = URLSession(configuration: configuration)
        sut = NetworkService(session: urlSession)
    }
    
    deinit {
        urlSession = nil
        sut = nil
    }
    
    // MARK: - GET Request Tests
    
    @Test("NetworkService GET success", .httpClientTransportSetup)
    func networkService_get_success() async throws {
        // Arrange
        let mockPost = MockPost(userId: 1, id: 1, title: "Mock Post Title", body: "This is a mock post body.")
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        // Encode the mock object to Data to simulate a successful API response
        let postData = try JSONEncoder().encode(mockPost)
        
        // Set up MockURLProtocol to intercept the request and return our mock data
        await MockURLProtocol.setHandler { [url](request: URLRequest) in
            // Assert that the request URL matches our expected URL
            #expect(request.url == url)
            // Create a successful HTTP response (status code 200 OK)
            let response = await self.createHTTPResponse(url: url, statusCode: 200)!
            // Return the mock response and data
            return (response, postData)
        }
        
        // Act
        // Make the GET request and decode the response into our MockPost type
        let fetchedPost: MockPost = try await sut.get(url)
        
        // Assert
        // Verify that the fetched data matches our mock post
        #expect(fetchedPost.id == mockPost.id)
        #expect(fetchedPost.title == mockPost.title)
        #expect(fetchedPost == mockPost) // More concise check if Equatable
    }
    
    @Test("NetworkService GET With Parameters Success", .httpClientTransportSetup)
    func networkService_getWithParameters_success() async throws {
        // Arrange
        let mockComments = [
            MockComment(id: 1, name: "Commenter 1", email: "c1@example.com", body: "First mock comment."),
            MockComment(id: 2, name: "Commenter 2", email: "c2@example.com", body: "Second mock comment.")
        ]
        let baseURL = URL(string: "https://example.com/test-comments")!
        let parameters = ["postId": "123", "limit": "2"] // Added another parameter for realism
        
        // Manually construct the expected URL with query parameters
        var urlComponents = try #require(URLComponents(url: baseURL, resolvingAgainstBaseURL: false))
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }.sorted { $0.name < $1.name } // Sort for consistent URL comparison
        
        let expectedURL = try #require(urlComponents.url)
        // Encode the mock comments array to Data
        let commentsData = try JSONEncoder().encode(mockComments)
        
        // Configure MockURLProtocol to handle the request with parameters
        await MockURLProtocol.setHandler { request in
            #expect(request.url?.scheme == expectedURL.scheme)
            #expect(request.url?.host == expectedURL.host)
            #expect(request.url?.path == expectedURL.path)
            
            let requestQueryItems = URLComponents(url: try #require(request.url), resolvingAgainstBaseURL: false)?
                .queryItems?
                .reduce(into: [String: String]()) { $0[$1.name] = $1.value } ?? [:]
            
            let expectedQueryItems = parameters.reduce(into: [String: String]()) { $0[$1.key] = $1.value }
            
            #expect(requestQueryItems == expectedQueryItems)
            
            let response = await self.createHTTPResponse(url: expectedURL, statusCode: 200)!
            return (response, commentsData)
        }
        
        // Act
        // Make the GET request with parameters and decode the response
        let fetchedComments: [MockComment] = try await sut.get(baseURL, parameters: parameters)
        
        // Assert
        // Verify the count and content of the fetched comments
        #expect(fetchedComments.count == mockComments.count)
        #expect(fetchedComments.first?.id == mockComments.first?.id)
        #expect(fetchedComments == mockComments) // More concise check if Equatable
    }
    
    // MARK: - POST Request Tests
    
    @Test("NetworkService POST Success", .httpClientTransportSetup)
    func networkService_post_success() async throws {
        // Arrange
        let url = URL(string: "https://example.com/test-photo")!
        let photoBody = mockPhotoPayload // Using our local mock payload
        
        await MockURLProtocol.setHandler { request in
            // Assert request details: URL, HTTP method, Content-Type header
            #expect(request.url == url)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            
            // Read the HTTP body from the intercepted request
            let requestHttpBody = try #require(request.readBody())
            // Decode the request body to verify it matches our expected payload
            let decodedBody = try JSONDecoder().decode(MockPhotoPayload.self, from: requestHttpBody)
            #expect(decodedBody.title == photoBody.title)
            #expect(decodedBody == photoBody) // More concise check
            
            // Create a successful HTTP response (status code 200 OK) with an empty data body
            let response = await self.createHTTPResponse(url: url, statusCode: 200)!
            return (response, Data())
        }
        
        // Act & Assert
        // The POST method here doesn't return a decodable type, so we just expect it not to throw.
        await #expect(throws: Never.self) { try await sut.post(url, body: photoBody) }
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Network Service GET Invalid Status Code", .httpClientTransportSetup)
    func networkService_get_invalidStatusCode() async throws {
        // Arrange
        let url = URL(string: "https://example.com/error-get")!
        await MockURLProtocol.setHandler { request in
            // Simulate a 404 Not Found error response
            let response = await self.createHTTPResponse(url: url, statusCode: 404)!
            return (response, Data())
        }
        
        // Act & Assert
        // Expect a NetworkingError to be thrown
        let thrownError = await #expect(throws: NetworkingError.self) {
            let _: MockPost = try await self.sut.get(url) // Attempt to fetch a Post
        }
        // Verify that the thrown error is NetworkingError.invalidStatusCode and its code is 404
        if case .invalidStatusCode(let code) = thrownError {
            #expect(code == 404)
        } else {
            // Record an issue if the wrong error type was thrown
            Issue.record("Expected NetworkingError.invalidStatusCode but got \(thrownError)")
        }
    }
    
    @Test("Network Service POST Invalid Status Code", .httpClientTransportSetup)
    func networkService_post_invalidStatusCode() async throws {
        // Arrange
        let url = URL(string: "https://example.com/error-post")!
        await MockURLProtocol.setHandler { request in
            // Simulate a 500 Internal Server Error response
            let response = await self.createHTTPResponse(url: url, statusCode: 500)!
            return (response, Data())
        }
        
        // Act & Assert
        // Expect a NetworkingError to be thrown
        let thrownError = await #expect(throws: NetworkingError.self) {
            try await self.sut.post(url, body: mockEmptyPayload) // Attempt to post with an empty payload
        }
        // Verify that the thrown error is NetworkingError.invalidStatusCode and its code is 500
        if case .invalidStatusCode(let code) = thrownError {
            #expect(code == 500)
        } else {
            // Record an issue if the wrong error type was thrown
            Issue.record("Expected NetworkingError.invalidStatusCode but got \(thrownError)")
        }
    }
    
    @Test("Network Service GET Decoding Failed", .httpClientTransportSetup)
    func networkService_get_decodingFailed() async throws {
        // Arrange
        let url = URL(string: "https://example.com/bad-data")!
        // Provide malformed JSON data that cannot be decoded into a MockPost
        let malformedData = "{\"notAValidPost\": \"data\", \"extra\": 123}".data(using: .utf8)!
        
        await MockURLProtocol.setHandler { request in
            // Simulate a successful HTTP response (status code 200 OK)
            let response = await self.createHTTPResponse(url: url, statusCode: 200)!
            // Return the malformed data
            return (response, malformedData)
        }
        
        // Act & Assert
        // Expect a NetworkingError to be thrown
        let thrownError = await #expect(throws: NetworkingError.self) {
            let _: MockPost = try await self.sut.get(url) // Attempt to fetch a Post
        }
        // Verify that the thrown error is NetworkingError.decodingFailed
        if case .decodingFailed = thrownError {
            // Success: decodingFailed was caught as expected
        } else {
            // Record an issue if the wrong error type was thrown
            Issue.record("Expected NetworkingError.decodingFailed but got \(thrownError)")
        }
    }
    
    @Test("Network Service GET Request Failed", .httpClientTransportSetup)
    func networkService_get_requestFailed() async throws {
        // Arrange
        let url = URL(string: "https://example.com/network-error")!
        // Simulate a common network error like being offline
        let networkError = URLError(.notConnectedToInternet)
        
        // Configure MockURLProtocol to explicitly throw a network error
        await MockURLProtocol.setHandler { request in
            throw networkError // This simulates an underlying network failure
        }
        
        // Act & Assert
        // Expect a NetworkingError to be thrown
        let thrownError = await #expect(throws: NetworkingError.self) {
            let _: MockPost = try await self.sut.get(url) // Attempt to fetch a Post
        }
        // Verify that the thrown error is NetworkingError.requestFailed and contains the original URLError code
        if case .requestFailed(let urlError) = thrownError {
            #expect(urlError.code == networkError.code)
        } else {
            // Record an issue if the wrong error type was thrown
            Issue.record("Expected NetworkingError.requestFailed but got \(thrownError)")
        }
    }
    
    // A custom error struct for testing the .otherError case
    struct CustomTestError: Error, LocalizedError, Equatable {
        let message: String
        var errorDescription: String? { return message }
    }
    
    @Test("Network Service GET otherError", .httpClientTransportSetup)
    func networkService_get_otherError() async throws {
        // Arrange
        let url = URL(string: "https://example.com/other-error")!
        let customError = CustomTestError(message: "A completely unexpected error occurred!")
        
        // Configure MockURLProtocol to throw our custom, unexpected error directly
        await MockURLProtocol.setHandler { request in
            throw customError // Simulate an arbitrary, unexpected error from the underlying network layer
        }
        
        // Act & Assert
        // Expect a NetworkingError to be thrown
        let thrownError = await #expect(throws: NetworkingError.self) {
            let _: MockPost = try await self.sut.get(url) // Attempt to fetch a Post
        }
        
        // Verify that the thrown error is NetworkingError.otherError.
        // We don't check the specific underlying error's content here, just that it's encapsulated.
        if case .otherError = thrownError {
            // Success: NetworkingError.otherError was caught as expected
        } else {
            // Record an issue if the wrong error type was thrown
            Issue.record("Expected NetworkingError.otherError but got \(thrownError)")
        }
    }
}

// MARK: - Helper Extension for NetworkServiceTests

// This extension provides utility methods specifically for the test class.
private extension NetworkServiceTests { // Renamed from NetworkServiceIntegrationTests to match class name
    /// Creates a basic HTTPURLResponse for mocking network responses.
    /// - Parameters:
    ///   - url: The URL for which the response is being created.
    ///   - statusCode: The HTTP status code for the response (e.g., 200, 404, 500).
    /// - Returns: An optional HTTPURLResponse object.
    @MainActor func createHTTPResponse(url: URL, statusCode: Int) -> HTTPURLResponse? {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
    }
}
