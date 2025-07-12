import SwiftUI

public struct AppView: View {
    @State private var preferredColumn: NavigationSplitViewColumn = .detail
    
    public init() {
        
    }
    
    public var body: some View {
        NavigationSplitView(preferredCompactColumn: $preferredColumn) {
            List {
                Section {
                    ForEach(NavigationOptions.mainPages) { page in
                        NavigationLink(value: page) {
                            Label(page.name, systemImage: page.symbolName)
                        }
                    }
                }
            }
            .navigationDestination(for: NavigationOptions.self) { page in
                NavigationStack {
                    page.viewForPage()
                }
            }
        } detail: {
            NavigationStack {
                NavigationOptions.requests.viewForPage()
            }
        }
    }
}

#Preview {
    AppView()
}
