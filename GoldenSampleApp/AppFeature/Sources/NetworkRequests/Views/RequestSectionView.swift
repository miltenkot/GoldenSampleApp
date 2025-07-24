import SwiftUI
import NetworkService

struct RequestSectionView<Content: View>: View {
    let error: NetworkingError?
    let content: () -> Content
    
    var body: some View {
        VStack(spacing: 0) {
            Text("Sending Post")
                .frame(maxWidth: .infinity, alignment: .leading)
                .font(.title)
                .bold()
            
            if let error {
                Text("Error: \(String(describing: error.errorDescription))")
                    .foregroundStyle(.red)
                    .padding()
            } else {
                content()
            }
        }
    }
}

#Preview {
    RequestSectionView(error: nil) {
        Text("Hello world")
    }
}
