import SwiftUI
import NetworkService

struct CommentsSectionView: View {
    let error: NetworkingError?
    var comments: [Comment]
    
    var body: some View {
        RequestSectionView(error: error) {
            Group {
                if !comments.isEmpty {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(comments) { comment in
                            VStack(alignment: .leading) {
                                Text("name \(comment.name)")
                                Text("emails \(comment.email)")
                                Divider()
                            }
                        }
                    }
                    .padding()
                } else {
                    Text("No data")
                }
            }
        }
    }
}
