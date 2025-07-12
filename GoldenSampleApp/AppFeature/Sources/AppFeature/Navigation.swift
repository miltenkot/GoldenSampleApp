import SwiftUI
import NetworkRequests

/// An enumeration of navigation options in the app.
enum NavigationOptions: Equatable, Hashable, Identifiable, CaseIterable {
    var id: Self { self }
    /// A case that represents viewing the dealing with api requests
    case requests
    
    static let mainPages: [NavigationOptions] = NavigationOptions.allCases
    
    var name: LocalizedStringResource {
        switch self {
        case .requests: return LocalizedStringResource("Network Requests", comment: "Title for the Requests tab, shown in the sidebar.")
        }
    }
    
    var symbolName: String {
        switch self {
        case .requests: "server.rack"
        }
    }
    
    /// A view builder that the split view uses to show a view for the selected navigation option.
    @MainActor @ViewBuilder func viewForPage() -> some View {
        switch self {
        case .requests: NetworkExampleView()
        }
    }
}
