import SwiftUI

// MARK: - ViewModel

@MainActor
@Observable
final class NetworkModel {
    private let networkService: NetworkServiceProtocol
    
    var post: Post?
    var comments: [Comment] = []
    
    var getPostError: NetworkingError?
    var getCommentsError: NetworkingError?
    var postValidPhotoError: NetworkingError?
    var postInvalidPhotoError: NetworkingError?
    
    var showProgressView = false
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchData() async {
        showProgressView = true
        defer { showProgressView = false }
        
        await fetchPost()
        await fetchComments()
        await postValidPhoto()
        await postInvalidPhoto()
    }
    
    private func fetchPost() async {
        do {
            post = try await networkService.get(URL(string: Constants.postURL)!)
            print(Constants.postTitlePrefix + (post?.title ?? ""))
        } catch let error as NetworkingError {
            getPostError = error
        } catch {
            print(Constants.unknownErrorPrefix + "\(error)")
        }
    }
    
    private func fetchComments() async {
        do {
            comments = try await networkService.get(
                URL(string: Constants.commentsURL)!,
                parameters: [Constants.postIdParameter: Constants.postIdValue]
            )
            print(Constants.commentsCountPrefix + "\(comments.count)")
        } catch let error as NetworkingError {
            getCommentsError = error
        } catch {
            print(Constants.unknownErrorPrefix + "\(error)")
        }
    }
    
    private func postValidPhoto() async {
        do {
            try await networkService.post(
                URL(string: Constants.photosURL)!,
                body: Photo(albumId: 1, id: "Id", title: "title", url: "url", thumbnailUrl: "thumbnailUrl")
            )
        } catch {
            postValidPhotoError = error
        }
    }
    
    private func postInvalidPhoto() async {
        do {
            try await networkService.post(
                URL(string: Constants.wrongPhotosURL)!,
                body: EmptyPhoto()
            )
        } catch {
            postInvalidPhotoError = error
        }
    }
}

extension NetworkModel {
    // MARK: - Constants

    private enum Constants {
        static let postURL = "https://jsonplaceholder.typicode.com/posts/1"
        static let commentsURL = "https://jsonplaceholder.typicode.com/comments"
        static let photosURL = "https://jsonplaceholder.typicode.com/photos"
        static let wrongPhotosURL = "https://jsonplaceholder.typicode.com/wrongphotos"
        static let postIdParameter = "postId"
        static let postIdValue = "1"
        static let postTitlePrefix = "📄 Post title: "
        static let commentsCountPrefix = "🧻 Comments count: "
        static let unknownErrorPrefix = "❌ Unknown error: "
    }
}
