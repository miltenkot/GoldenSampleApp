import SwiftUI
import NetworkService
import FactoryKit

// MARK: - ViewModel

@MainActor
@Observable
final class NetworkModel {
    @ObservationIgnored @Injected(\.networkUseCase) private var networkUseCase
    
    var post: Post?
    var comments: [Comment] = []
    
    var getPostError: NetworkingError?
    var getCommentsError: NetworkingError?
    var postValidPhotoError: NetworkingError?
    var postInvalidPhotoError: NetworkingError?
    
    var showProgressView = false
    
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
            post = try await networkUseCase.fetchPost()
            print(Constants.postTitlePrefix + (post?.title ?? ""))
        } catch {
            getPostError = error
        }
    }
    
    private func fetchComments() async {
        do {
            comments = try await networkUseCase.fetchComments()
            print(Constants.commentsCountPrefix + "\(comments.count)")
        } catch {
            getCommentsError = error
        }
    }
    
    private func postValidPhoto() async {
        do {
            try await networkUseCase.postValidPhoto()
        } catch {
            postValidPhotoError = error
        }
    }
    
    private func postInvalidPhoto() async {
        do {
            try await networkUseCase.postInvalidPhoto()
        } catch {
            postInvalidPhotoError = error
        }
    }
}

extension NetworkModel {
    
    // MARK: - Constants

    private enum Constants {
        static let postTitlePrefix = "📄 Post title: "
        static let commentsCountPrefix = "🧻 Comments count: "
        static let unknownErrorPrefix = "❌ Unknown error: "
    }
}
