import Foundation
@_exported import NetworkService
@testable import NetworkRequests

@MainActor
final class MockNetworkService: NetworkServiceProtocol {
    var getHandler: ((URL) async throws(NetworkingError) -> Any)?
    var getWithParametersHandler: ((URL, [String: String]) async throws(NetworkingError) -> Any)?
    var postHandler: (@MainActor(URL, Any) async throws(NetworkingError) -> Void)?
    
    func get<T>(_ url: URL) async throws(NetworkingError) -> T where T : Decodable {
        try await getHandler?(url) as! T
    }
    
    func get<T>(_ url: URL, parameters: [String : String]) async throws(NetworkingError) -> T where T : Decodable {
        guard let result = try await getWithParametersHandler?(url, parameters) as? T else {
            throw NetworkingError.otherError(NSError(domain: "MockNetworkService", code: -2))
        }
        return result
    }
    
    func post<T>(_ url: URL, body: T) async throws(NetworkingError) where T : Encodable {
        guard let postHandler else {
            throw NetworkingError.otherError(NSError(domain: "MockNetworkService", code: -3))
        }
        try await postHandler(url, body)
    }
}
