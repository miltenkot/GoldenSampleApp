@_exported import NetworkService
@testable import NetworkRequests

@MainActor
final class MockNetworkUseCase: NetworkUseCaseProtocol {
    
    // MARK: - Handlers
    
    var fetchPostHandler: (() async throws(NetworkingError) -> Post)?
    var fetchCommentsHandler: (() async throws(NetworkingError) -> [Comment])?
    var postValidPhotoHandler: (() async throws(NetworkingError) -> Void)?
    var postInvalidPhotoHandler: (() async throws(NetworkingError) -> Void)?
    
    // MARK: - Protocol Conformance
    
    func fetchPost() async throws(NetworkingError) -> Post? {
        if let handler = fetchPostHandler {
            return try await handler()
        } else {
            return Post(userId: 1, id: 1, title: "title", body: "body")
        }
    }
    
    func fetchComments() async throws(NetworkingError) -> [Comment] {
        if let handler = fetchCommentsHandler {
            return try await handler()
        } else {
            return [Comment(id: 1, name: "name", email: "email", body: "body")]
        }
    }
    
    func postValidPhoto() async throws(NetworkingError) {
        if let handler = postValidPhotoHandler {
            try await handler()
        }
    }
    
    func postInvalidPhoto() async throws(NetworkingError) {
        if let handler = postInvalidPhotoHandler {
            try await handler()
        }
    }
}
