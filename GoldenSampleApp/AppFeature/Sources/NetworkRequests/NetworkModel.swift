import SwiftUI

// MARK: - ViewModel

@MainActor
@Observable
final class NetworkModel {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
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
        
        do {
            post = try await networkService.get(URL(string: "https://jsonplaceholder.typicode.com/posts/1")!)
            print("📄 Post title: \(post?.title ?? "")")
        } catch let error as NetworkingError {
            getPostError = error
        } catch {
            print("❌ Unknown error: \(error)")
        }
        
        do {
            comments = try await networkService.get(
                URL(string: "https://jsonplaceholder.typicode.com/comments")!,
                parameters: ["postId": "1"]
            )
            print("🧻 Comments count: \(comments.count)")
        } catch let error as NetworkingError {
            getCommentsError = error
        } catch {
            print("❌ Unknown error: \(error)")
        }
        
        do {
            try await networkService.post(
                URL(string: "https://jsonplaceholder.typicode.com/photos")!,
                body: Photo(albumId: 1, id: "Id", title: "title", url: "url", thumbnailUrl: "thumbnailUrl")
            )
        } catch {
            postValidPhotoError = error
        }
        
        do {
            try await networkService.post(
                URL(string: "https://jsonplaceholder.typicode.com/wrongphotos")!,
                body: EmptyPhoto()
            )
        } catch {
            postInvalidPhotoError = error
        }
    }
}
