import Testing
import SwiftUI
import Foundation
import FactoryKit
import FactoryTesting

@testable import NetworkRequests

@MainActor
@Suite(.container)
struct NetworkModelTests {

    // MARK: - Properties

    var sut: NetworkModel!
    var mockNetworkUseCase: MockNetworkUseCase!

    // MARK: - Setup and Teardown

    init() {
        let mock = MockNetworkUseCase()
        Container.shared.networkUseCase.register { mock }
        mockNetworkUseCase = mock
        sut = NetworkModel()
    }

    @Test func reset() async {
        mockNetworkUseCase.fetchPostHandler = nil
        mockNetworkUseCase.fetchCommentsHandler = nil
        mockNetworkUseCase.postValidPhotoHandler = nil
        mockNetworkUseCase.postInvalidPhotoHandler = nil

        sut.post = nil
        sut.comments = []
        sut.getPostError = nil
        sut.getCommentsError = nil
        sut.postValidPhotoError = nil
        sut.postInvalidPhotoError = nil
        sut.showProgressView = false
    }

    // MARK: - Test Cases

    @Test("Test fetchData when all network calls succeed")
    func fetchData_Success() async throws {
        let expectedPost = Post(userId: 1, id: 1, title: "Test Post", body: "This is a test post body.")
        let expectedComments = [
            Comment(id: 1, name: "Commenter 1", email: "c1@example.com", body: "Great post!"),
            Comment(id: 2, name: "Commenter 2", email: "c2@example.com", body: "Very informative.")
        ]

        mockNetworkUseCase.fetchPostHandler = {
            return expectedPost
        }
        mockNetworkUseCase.fetchCommentsHandler = {
            return expectedComments
        }
        mockNetworkUseCase.postValidPhotoHandler = {
            // Simulate success (no throw)
        }
        mockNetworkUseCase.postInvalidPhotoHandler = {
            // Simulate success (no throw)
        }

        await sut.fetchData()

        #expect(sut.post == expectedPost)
        #expect(sut.comments == expectedComments)
        #expect(sut.getPostError == nil)
        #expect(sut.getCommentsError == nil)
        #expect(sut.postValidPhotoError == nil)
        #expect(sut.postInvalidPhotoError == nil)
        #expect(sut.showProgressView == false)
    }

    @Test("Test fetchData when fetchPost fails")
    func fetchData_FetchPostFailure() async throws(NetworkingError) {
        let expectedError = NetworkingError.invalidStatusCode(500)

        mockNetworkUseCase.fetchPostHandler = { () throws(NetworkingError) in
            throw expectedError
        }
        mockNetworkUseCase.fetchCommentsHandler = {
            return [Comment(id: 1, name: "name", email: "email", body: "body")]
        }
        mockNetworkUseCase.postValidPhotoHandler = { }
        mockNetworkUseCase.postInvalidPhotoHandler = { }

        await sut.fetchData()

        #expect(sut.getPostError == expectedError)
        #expect(sut.post == nil)
        #expect(sut.comments.count == 1)
        #expect(sut.getCommentsError == nil)
        #expect(sut.postValidPhotoError == nil)
        #expect(sut.postInvalidPhotoError == nil)
        #expect(sut.showProgressView == false)
    }

    @Test("Test fetchData when fetchComments fails")
    func fetchData_FetchCommentsFailure() async throws {
        let expectedError = NetworkingError.otherError(NSError(domain: "", code: 0, userInfo: nil))

        mockNetworkUseCase.fetchPostHandler = {
            return Post(userId: 1, id: 1, title: "title", body: "body")
        }
        mockNetworkUseCase.fetchCommentsHandler = { () throws(NetworkingError) in
            throw expectedError
        }
        mockNetworkUseCase.postValidPhotoHandler = { }
        mockNetworkUseCase.postInvalidPhotoHandler = { }

        await sut.fetchData()

        #expect(sut.getCommentsError == expectedError)
        #expect(sut.comments.isEmpty)
        #expect(sut.post != nil)
        #expect(sut.getPostError == nil)
        #expect(sut.postValidPhotoError == nil)
        #expect(sut.postInvalidPhotoError == nil)
        #expect(sut.showProgressView == false)
    }

    @Test("Test fetchData when postValidPhoto fails")
    func fetchData_PostValidPhotoFailure() async throws {
        let expectedError = NetworkingError.otherError(NSError(domain: "", code: 0, userInfo: nil))

        mockNetworkUseCase.fetchPostHandler = {
            return Post(userId: 1, id: 1, title: "title", body: "body")
        }
        mockNetworkUseCase.fetchCommentsHandler = {
            return [Comment(id: 1, name: "name", email: "email", body: "body")]
        }
        mockNetworkUseCase.postValidPhotoHandler = { () throws(NetworkingError) in
            throw expectedError
        }
        mockNetworkUseCase.postInvalidPhotoHandler = { }

        await sut.fetchData()

        #expect(sut.postValidPhotoError == expectedError)
        #expect(sut.post != nil)
        #expect(sut.comments.count == 1)
        #expect(sut.getPostError == nil)
        #expect(sut.getCommentsError == nil)
        #expect(sut.postInvalidPhotoError == nil)
        #expect(sut.showProgressView == false)
    }

    @Test("Test fetchData when postInvalidPhoto fails")
    func fetchData_PostInvalidPhotoFailure() async throws {
        let expectedError = NetworkingError.decodingFailed(
            DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: ""))
        )
        
        mockNetworkUseCase.fetchPostHandler = {
            return Post(userId: 1, id: 1, title: "title", body: "body")
        }
        mockNetworkUseCase.fetchCommentsHandler = {
            return [Comment(id: 1, name: "name", email: "email", body: "body")]
        }
        mockNetworkUseCase.postValidPhotoHandler = { }
        mockNetworkUseCase.postInvalidPhotoHandler = { () throws(NetworkingError) in
            throw expectedError
        }

        await sut.fetchData()

        #expect(sut.postInvalidPhotoError == expectedError)
        #expect(sut.post != nil)
        #expect(sut.comments.count == 1)
        #expect(sut.getPostError == nil)
        #expect(sut.getCommentsError == nil)
        #expect(sut.postValidPhotoError == nil)
        #expect(sut.showProgressView == false)
    }

    @Test("Test fetchData when all network calls fail")
    func fetchData_AllFailures() async throws {
        let postError = NetworkingError.requestFailed(URLError(.badURL))
        let commentsError = NetworkingError.requestFailed(URLError(.badURL))
        let validPhotoError = NetworkingError.requestFailed(URLError(.badURL))
        let invalidPhotoError = NetworkingError.requestFailed(URLError(.badURL))

        mockNetworkUseCase.fetchPostHandler = { () throws(NetworkingError) in throw postError }
        mockNetworkUseCase.fetchCommentsHandler = { () throws(NetworkingError) in throw commentsError }
        mockNetworkUseCase.postValidPhotoHandler = { () throws(NetworkingError) in throw validPhotoError }
        mockNetworkUseCase.postInvalidPhotoHandler = { () throws(NetworkingError) in throw invalidPhotoError }

        await sut.fetchData()

        #expect(sut.getPostError == postError)
        #expect(sut.getCommentsError == commentsError)
        #expect(sut.postValidPhotoError == validPhotoError)
        #expect(sut.postInvalidPhotoError == invalidPhotoError)

        #expect(sut.post == nil)
        #expect(sut.comments.isEmpty)
        #expect(sut.showProgressView == false)
    }

    @Test("Test fetchData with default mock behavior (no handlers set)")
    func fetchData_DefaultMockBehavior() async throws {
        // Given: No handlers are set on the mock, so it will use its default return values

        // When: Call fetchData
        await sut.fetchData()

        // Then: Assert that the default values are returned and no errors occurred
        #expect(sut.post == Post(userId: 1, id: 1, title: "title", body: "body"))
        #expect(sut.comments == [Comment(id: 1, name: "name", email: "email", body: "body")])
        #expect(sut.getPostError == nil)
        #expect(sut.getCommentsError == nil)
        #expect(sut.postValidPhotoError == nil)
        #expect(sut.postInvalidPhotoError == nil)
        #expect(sut.showProgressView == false)
    }
}

extension Post: Equatable {
    public static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.userId == rhs.userId &&
        lhs.id == rhs.id &&
        lhs.title == rhs.title &&
        lhs.body == rhs.body
    }
}

extension NetworkRequests.Comment: Equatable {
    public static func == (lhs: NetworkRequests.Comment, rhs: NetworkRequests.Comment) -> Bool {
        lhs.id == rhs.id &&
        lhs.name == rhs.name &&
        lhs.email == rhs.email &&
        lhs.body == rhs.body
    }
}
