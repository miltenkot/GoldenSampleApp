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

#Preview {
    NetworkExampleScreen()
}
