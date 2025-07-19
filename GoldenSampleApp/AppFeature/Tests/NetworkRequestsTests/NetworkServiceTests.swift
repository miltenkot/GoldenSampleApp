import Testing
@preconcurrency import Foundation
@testable import NetworkRequests

@MainActor
@Suite("Network Service Tests", .serialized)
final class NetworkServiceTests {
    let mockPhoto = Photo(albumId: 1, id: "1", title: "Mock Photo Title", url: "mockurl.com", thumbnailUrl: "mockthumbnail.com")
    let mockEmptyPhoto = EmptyPhoto()
    
    var sut: NetworkService!
    var urlSession: URLSession!
    
    typealias Comment = NetworkRequests.Comment
    
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
    
    @Test("NetworkService GET success", .httpClientTransportSetup)
    func networkService_get_success() async throws {
        // Arrange
        let mockPost = Post(userId: 1, id: 1, title: "Mock Post Title", body: "This is a mock post body.")
        let url = URL(string: "https://jsonplaceholder.typicode.com/posts/1")!
        let postData = try JSONEncoder().encode(mockPost)
        
        await MockURLProtocol.setHandler { [url](request: URLRequest) in
            #expect(request.url == url)
            let response = await self.createHTTPResponse(url: url, statusCode: 200)!
            return (response, postData)
        }
        
        // Act
        let fetchedPost: Post = try await sut.get(url)
        
        // Assert
        #expect(fetchedPost.id == mockPost.id)
        #expect(fetchedPost.title == mockPost.title)
    }
    
    
    @Test("NetworkService GET With Parameters Success", .httpClientTransportSetup)
    func networkService_getWithParameters_success() async throws {
        // Arrange
        let mockComments = [
            Comment(id: 1, name: "Commenter 1", email: "c1@example.com", body: "First mock comment."),
            Comment(id: 2, name: "Commenter 2", email: "c2@example.com", body: "Second mock comment.")
        ]
        let baseURL = URL(string: "https://example.com/test-comments")!
        let parameters = ["postId": "123"]
        
        var urlComponents = try #require(URLComponents(url: baseURL, resolvingAgainstBaseURL: false))
        urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        let expectedURL = try #require(urlComponents.url)
        let commentsData = try JSONEncoder().encode(mockComments)
        
        await MockURLProtocol.setHandler { request in
            #expect(request.url == expectedURL)
            let response = await self.createHTTPResponse(url: expectedURL, statusCode: 200)!
            return (response, commentsData)
        }
        
        // Act
        let fetchedComments: [Comment] = try await sut.get(baseURL, parameters: parameters)
        
        // Assert
        #expect(fetchedComments.count == mockComments.count)
        #expect(fetchedComments.first?.id == mockComments.first?.id)
    }
    
    @Test("NetworkService POST Success", .httpClientTransportSetup)
    func networkService_post_success() async throws {
        // Arrange
        let url = URL(string: "https://example.com/test-photo")!
        let photoBody = mockPhoto
        
        await MockURLProtocol.setHandler { request in
            #expect(request.url == url)
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
            
            let requestHttpBody = try #require(request.readBody())
            let decodedBody = try JSONDecoder().decode(Photo.self, from: requestHttpBody)
            #expect(decodedBody.title == photoBody.title)
            
            let response = await self.createHTTPResponse(url: url, statusCode: 200)!
            return (response, Data())
        }
        
        // Act & Assert
        await #expect(throws: Never.self) { try await sut.post(url, body: photoBody) }
    }
    
    @Test("Network Service GET Invalid Status Code", .httpClientTransportSetup)
    func networkService_get_invalidStatusCode() async throws {
        // Arrange
        let url = URL(string: "https://example.com/error-get")!
        await MockURLProtocol.setHandler { request in
            let response = await self.createHTTPResponse(url: url, statusCode: 404)!
            return (response, Data())
        }
        
        // Act & Assert
        let thrownError = await #expect(throws: NetworkingError.self) {
            let _: Post = try await self.sut.get(url)
        }
        if case .invalidStatusCode(let code) = thrownError {
            #expect(code == 404)
        } else {
            Issue.record("Expected NetworkingError.invalidStatusCode but got \(thrownError)")
        }
    }
    
    @Test("Network Service POST Invalid Status Code", .httpClientTransportSetup)
    func networkService_post_invalidStatusCode() async throws {
        // Arrange
        let url = URL(string: "https://example.com/error-post")!
        await MockURLProtocol.setHandler { request in
            let response = await self.createHTTPResponse(url: url, statusCode: 500)!
            return (response, Data())
        }
        
        // Act & Assert
        let thrownError = await #expect(throws: NetworkingError.self) {
            try await self.sut.post(url, body: mockEmptyPhoto)
        }
        if case .invalidStatusCode(let code) = thrownError {
            #expect(code == 500)
        } else {
            Issue.record("Expected NetworkingError.invalidStatusCode but got \(thrownError)")
        }
    }
    
    @Test("Network Service GET Decoding Failed", .httpClientTransportSetup)
    func networkService_get_decodingFailed() async throws {
        // Arrange
        let url = URL(string: "https://example.com/bad-data")!
        let malformedData = "{\"notAValidPost\": \"data\"}".data(using: .utf8)! // Not decodable as Post
        
        await MockURLProtocol.setHandler { request in
            let response = await self.createHTTPResponse(url: url, statusCode: 200)!
            return (response, malformedData)
        }
        
        // Act & Assert
        
        let thrownError = await #expect(throws: NetworkingError.self) {
            let _: Post = try await self.sut.get(url)
        }
        if case .decodingFailed = thrownError {
            // Success: decodingFailed was caught
        } else {
            Issue.record("Expected NetworkingError.decodingFailed but got \(thrownError)")
        }
    }
    
    @Test("Network Service GET Request Failed", .httpClientTransportSetup)
    func networkService_get_requestFailed() async throws {
        // Arrange
        let url = URL(string: "https://example.com/network-error")!
        let networkError = URLError(.notConnectedToInternet)
        
        await MockURLProtocol.setHandler { request in
            throw networkError // Simulate a network failure
        }
        
        // Act & Assert
        let thrownError = await #expect(throws: NetworkingError.self) {
            let _: Post = try await self.sut.get(url)
        }
        if case .requestFailed(let urlError) = thrownError {
            #expect(urlError.code == networkError.code)
        } else {
            Issue.record("Expected NetworkingError.requestFailed but got \(thrownError)")
        }
    }
    
    struct CustomTestError: Error, LocalizedError, Equatable {
        let message: String
        var errorDescription: String? { return message }
    }
    
    @Test("Network Service GET otherError", .httpClientTransportSetup)
    func networkService_get_otherError() async throws {
        // Arrange
        let url = URL(string: "https://example.com/other-error")!
        let customError = CustomTestError(message: "A completely unexpected error occurred!")
        
        // Configure MockURLProtocol to throw our custom error directly
        await MockURLProtocol.setHandler { request in
            throw customError // Simulate an arbitrary, unexpected error from the underlying network layer
        }
        
        // Act & Assert
        let thrownError = await #expect(throws: NetworkingError.self) {
            let _: Post = try await self.sut.get(url)
        }
        
        // Verify that the thrown error is NetworkingError.otherError and contains our custom error
        if case .otherError(_) = thrownError {
            // Success: CustomTestError was caught
        } else {
            Issue.record("Expected NetworkingError.otherError but got \(thrownError)")
        }
    }
}

private extension NetworkServiceTests {
    @MainActor func createHTTPResponse(url: URL, statusCode: Int) -> HTTPURLResponse? {
        HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)
    }
}
