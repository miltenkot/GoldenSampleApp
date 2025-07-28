import SwiftUI

public struct NetworkExampleScreen: View {
    private let model = NetworkModel()
    
    public init() {
        
    }
    
    public var body: some View {
        ScrollView(.vertical) {
            PostSectionView(error: model.getPostError, post: model.post)
                .padding()
            
            CommentsSectionView(error: model.getCommentsError, comments: model.comments)
                .padding()
            
            PhotoPostStatusView(error: model.postValidPhotoError)
                .padding()
            
            PhotoPostStatusView(error: model.postInvalidPhotoError)
                .padding()
        }
        .overlay {
            if model.showProgressView {
                ProgressView()
            }
        }
        .task {
            await model.fetchData()
        }
    }
}
#if DEBUG

import FactoryKit
import NetworkService

class NetworkUseCasePreview: NetworkUseCaseProtocol {
    func fetchPost() async throws(NetworkingError) -> Post? {
        Post(userId: 1, id: 1, title: "same title", body: "This is a mock post body. It contains some sample text to simulate real content for testing purposes.")
    }
    
    func fetchComments() async throws(NetworkingError) -> [Comment] {
        [
            Comment(id: 201, name: "User One", email: "user1@example.com", body: "Great post! Really enjoyed reading this."),
            Comment(id: 202, name: "Commentator X", email: "commentator.x@mail.com", body: "I have a slightly different opinion on this topic, but well-written!"),
            Comment(id: 203, name: "Anonymous Reader", email: "anon@web.org", body: "Simple and to the point. Thanks for sharing."),
            
        ]
    }
    
    func postValidPhoto() async throws(NetworkingError) {
        
    }
    
    func postInvalidPhoto() async throws(NetworkingError) {
        throw NetworkingError.invalidStatusCode(404)
    }
}


#Preview {
    Container.shared.networkUseCase.preview { NetworkUseCasePreview() }
    NetworkExampleScreen()
}

#endif
