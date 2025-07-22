import Testing
import SwiftUI
import Foundation

@testable import NetworkRequests

@MainActor
struct NetworkUseCaseTests {
    var sut: NetworkUseCase!
    var mockNetworkService: MockNetworkService!
    
    init() {
        mockNetworkService = MockNetworkService()
        sut = NetworkUseCase(networkService: mockNetworkService)
    }
    
    // MARK: - fetchPost Tests
    
    @Test("fetchPost returns a Post on success")
    func fetchPost_success() async throws {
        let expectedPost = Post(userId: 1, id: 1, title: "Test Post", body: "This is a test post body.")
        mockNetworkService.getHandler = { url in
            #expect(url == URL(string: "https://jsonplaceholder.typicode.com/posts/1")!)
            return expectedPost
        }
        
        // When: fetchPost is called
        let fetchedPost = try await sut.fetchPost()
        
        // Then: The correct post is returned
        #expect(fetchedPost == expectedPost, "Fetched post should match the expected post")
    }
    
    @Test("fetchPost throws error on network failure")
    func fetchPost_failure() async throws {
        // Given: MockNetworkService is configured to throw an error
        let expectedError = NetworkingError.invalidStatusCode(500)
        mockNetworkService.getHandler = { url throws(NetworkingError) in
            throw expectedError
        }
        
        // When & Then: fetchPost throws the expected error
        await #expect(throws: expectedError) {
            try await sut.fetchPost()
        }
    }
    
    // MARK: - fetchComments Tests
    
    @Test("fetchComments returns an array of Comments on success")
    func fetchComments_success() async throws {
        // Given: MockNetworkService is configured to return an array of Comments
        let expectedComments = [
            Comment(id: 1, name: "Comment 1", email: "a@b.com", body: "Body 1"),
            Comment(id: 2, name: "Comment 2", email: "c@d.com", body: "Body 2")
        ]
        mockNetworkService.getWithParametersHandler = { url, parameters in
            #expect(url == URL(string: "https://jsonplaceholder.typicode.com/comments")!)
            #expect(parameters["postId"] == "1")
            return expectedComments
        }
        
        // When: fetchComments is called
        let fetchedComments = try await sut.fetchComments()
        
        // Then: The correct comments are returned
        #expect(fetchedComments == expectedComments, "Fetched comments should match the expected comments")
    }
    
    @Test("fetchComments throws error on network failure")
    func fetchComments_failure() async throws {
        // Given: MockNetworkService is configured to throw an error
        let expectedError = NetworkingError.requestFailed(URLError(.unknown))
        mockNetworkService.getWithParametersHandler = { url, parameters throws(NetworkingError) in
            throw expectedError
        }
        
        // When & Then: fetchComments throws the expected error
        await #expect(throws: expectedError) {
            try await sut.fetchComments()
        }
    }
    
    // MARK: - postValidPhoto Tests
    
    @Test("postValidPhoto completes successfully on valid photo post")
    func postValidPhoto_success() async throws {
        // Given: MockNetworkService is configured to complete successfully
        mockNetworkService.postHandler = { url, body in
            #expect(url == URL(string: "https://jsonplaceholder.typicode.com/photos")!)
            let photoBody = body as! Photo
            
            #expect(photoBody.albumId == 1)
            #expect(photoBody.id == "Id")
            #expect(photoBody.title == "title")
            // No throw means success
        }
        
        // When: postValidPhoto is called
        // Then: It should not throw an error
        try await sut.postValidPhoto()
    }
    
    @Test("postValidPhoto throws error on network failure")
    func postValidPhoto_failure() async throws {
        // Given: MockNetworkService is configured to throw an error
        let expectedError = NetworkingError.requestFailed(URLError(.cannotConnectToHost))
        mockNetworkService.postHandler = { url, body throws(NetworkingError) in
            throw expectedError
        }
        
        // When & Then: postValidPhoto throws the expected error
        await #expect(throws: expectedError) {
            try await sut.postValidPhoto()
        }
    }
    
    // MARK: - postInvalidPhoto Tests
    
    @Test("postInvalidPhoto completes successfully on invalid photo post (if service allows)")
    func postInvalidPhoto_success() async throws {
        // Given: MockNetworkService is configured to complete successfully
        mockNetworkService.postHandler = { url, body in
            #expect(url == URL(string: "https://jsonplaceholder.typicode.com/wrongphotos")!)
            #expect(body as? EmptyPhoto != nil)
        }
        
        // When: postInvalidPhoto is called
        // Then: It should not throw an error
        try await sut.postInvalidPhoto()
    }
    
    @Test("postInvalidPhoto throws error on network failure")
    func postInvalidPhoto_failure() async throws {
        // Given: MockNetworkService is configured to throw an error
        let expectedError = NetworkingError.invalidStatusCode(400)
        mockNetworkService.postHandler = { url, body throws(NetworkingError) in
            throw expectedError
        }
        
        // When & Then: postInvalidPhoto throws the expected error
        await #expect(throws: expectedError) {
            try await sut.postInvalidPhoto()
        }
    }
    
    // Other cases
    
    @Test("fetchComments throws otherError when getWithParametersHandler is not set or returns wrong type")
    func fetchComments_throwsOtherError_whenGetWithParametersHandlerNotSet() async {
        let expectedNSError = NSError(domain: "MockNetworkService", code: -2)
        let expectedError = NetworkingError.otherError(expectedNSError)
        
        await #expect(throws: expectedError) {
            try await sut.fetchComments()
        }
    }
    
    @Test("postValidPhoto throws otherError when postHandler is not set")
    func postValidPhoto_throwsOtherError_whenPostHandlerNotSet() async {
        let expectedNSError = NSError(domain: "MockNetworkService", code: -3)
        let expectedError = NetworkingError.otherError(expectedNSError)
        
        await #expect(throws: expectedError) {
            try await sut.postValidPhoto()
        }
    }
    
    @Test("postInvalidPhoto throws otherError when postHandler is not set")
    func postInvalidPhoto_throwsOtherError_whenPostHandlerNotSet() async {
        let expectedNSError = NSError(domain: "MockNetworkService", code: -3)
        let expectedError = NetworkingError.otherError(expectedNSError)
        
        await #expect(throws: expectedError) {
            try await sut.postInvalidPhoto()
        }
    }
    
}
