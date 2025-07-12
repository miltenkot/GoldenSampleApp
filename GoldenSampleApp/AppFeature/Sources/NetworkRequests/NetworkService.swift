import Foundation

// MARK: - Network Service Protocol

@MainActor
protocol NetworkServiceProtocol {
    func get<T: Decodable>(_ url: URL) async throws -> T
    func get<T: Decodable>(_ url: URL, parameters: [String: String]) async throws -> T
    func post<T: Encodable>(_ url: URL, body: T) async throws(NetworkingError)
}

// MARK: - Network Service Implementation

@MainActor
final class NetworkService: NetworkServiceProtocol {
    func get<T: Decodable>(_ url: URL) async throws -> T {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            try validate(response)
            return try decode(data)
        } catch {
            throw map(error)
        }
    }
    
    func get<T: Decodable>(_ url: URL, parameters: [String: String]) async throws -> T {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let finalURL = components.url else {
            throw URLError(.badURL)
        }
        
        return try await get(finalURL)
    }
    
    func post<T: Encodable>(_ url: URL, body: T) async throws(NetworkingError) {
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try JSONEncoder().encode(body)
            
            let (_, response) = try await URLSession.shared.data(for: request)
            try validate(response)
        } catch {
            throw map(error)
        }
    }
    
    // MARK: - Private Helpers
    
    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NetworkingError.invalidStatusCode((response as? HTTPURLResponse)?.statusCode ?? -1)
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
