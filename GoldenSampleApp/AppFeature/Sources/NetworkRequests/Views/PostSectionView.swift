import SwiftUI

struct PostSectionView: View {
    let error: NetworkingError?
    let post: Post?
    
    var body: some View {
        RequestSectionView(error: error) {
            Group {
                if let post {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("userId: \(post.userId)")
                        Text("id: \(post.id)")
                        Text("title: \(post.title)")
                        Text("body: \(post.body)")
                    }
                    .padding()
                }
            }
        }
    }
}
