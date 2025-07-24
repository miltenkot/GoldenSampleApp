import SwiftUI
import NetworkService

struct PhotoPostStatusView: View {
    let error: NetworkingError?
    
    var body: some View {
        RequestSectionView(error: error) {
            Text("Success")
                .foregroundStyle(.green)
                .font(.title3)
                .bold()
                .padding()
        }
    }
}
