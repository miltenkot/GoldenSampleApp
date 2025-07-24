import Foundation

// MARK: - Network Service Protocol

@MainActor
public protocol NetworkServiceProtocol {
    func get<T: Decodable>(_ url: URL) async throws(NetworkingError) -> T
    func get<T: Decodable>(_ url: URL, parameters: [String: String]) async throws(NetworkingError) -> T
    func post<T: Encodable>(_ url: URL, body: T) async throws(NetworkingError)
}

// MARK: - Network Service Implementation

@MainActor
public final class NetworkService: NetworkServiceProtocol {
    let session: URLSession
    
    public init(session: URLSession = URLSession.shared) {
        self.session = session
    }
    
    public func get<T: Decodable>(_ url: URL) async throws(NetworkingError) -> T {
        do {
            let (data, response) = try await session.data(from: url)
            try validate(response)
            return try decode(data)
        } catch {
            throw map(error)
        }
    }
    
    public func get<T: Decodable>(_ url: URL, parameters: [String: String]) async throws(NetworkingError) -> T {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        // // components.url always returns a non-nil URL as long as the input URL is valid (non-nil)
        return try await get(components.url!)
    }
    
    public func post<T: Encodable>(_ url: URL, body: T) async throws(NetworkingError) {
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
            
            let (_, response) = try await session.data(for: request)
            try validate(response)
        } catch {
            throw map(error)
        }
    }
    
    // MARK: - Private Helpers
    
    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            // The forced unwrap (response as? HTTPURLResponse)! inside the else block cannot be nil, since the guard ensures response is an HTTPURLResponse. Thus, the case of it being nil does not occur.
            throw NetworkingError.invalidStatusCode((response as? HTTPURLResponse)!.statusCode)
        }
    }
    
    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkingError.decodingFailed(error)
        }
    }
    
    private func map(_ error: Error) -> NetworkingError {
        switch error {
        case let error as URLError:
            return .requestFailed(error)
        case let error as NetworkingError:
            return error
        default:
            return .otherError(error)
        }
    }
}
