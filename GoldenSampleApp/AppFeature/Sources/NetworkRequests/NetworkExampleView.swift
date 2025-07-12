import SwiftUI

public struct NetworkExampleView: View {
    private let model = NetworkModel()
    
    public init() {
        
    }
    
    public var body: some View {
        ScrollView(.vertical) {
            post(error: model.getPostError)
                .padding()
            comments(error: model.getCommentsError)
                .padding()
            
            photoPostStatus(error: model.postValidPhotoError)
                .padding()
            
            photoPostStatus(error: model.postInvalidPhotoError)
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
    
    @ViewBuilder
    private func post(error: NetworkingError?) -> some View {
        if let error {
            Text("Error: \(String(describing: error.errorDescription))")
                .foregroundStyle(.red)
        } else {
            VStack(spacing: 0) {
                Text("Posts")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title)
                    .bold()
                if let post = model.post {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("userId: \(post.userId)")
                        Text("id: \(post.id)")
                        Text("title: \(post.title)")
                        Text("body: \(post.body)")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func comments(error: NetworkingError?) -> some View {
        if let error {
            Text("Error: \(String(describing: error.errorDescription))")
                .foregroundStyle(.red)
        } else {
            VStack(spacing: 0) {
                Text("Comments")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .font(.title)
                    .bold()
                if !model.comments.isEmpty {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(model.comments) { comment in
                            VStack(alignment: .leading) {
                                Text("name \(comment.name)")
                                Text("emails \(comment.email)")
                                Divider()
                            }
                        }
                    }
                } else {
                    Text("No data")
                }
            }
        }
    }
    
    @ViewBuilder
    private func photoPostStatus(error: NetworkingError?) -> some View {
        VStack(spacing: 0) {
            Text("Sending Post")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title)
                .bold()
            Group {
                if let error {
                    Text("Error: \(String(describing: error.errorDescription))")
                        .foregroundStyle(.red)
                } else {
                    Text("Success")
                        .foregroundStyle(.green)
                    
                }
            }
            .font(.title3)
            .bold()
            .padding()
        }
    }
}

#Preview {
    NetworkExampleView()
}
