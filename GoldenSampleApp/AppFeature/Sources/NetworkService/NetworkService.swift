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
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    public init(session: URLSession = .shared,
                encoder: JSONEncoder = JSONEncoder(),
                decoder: JSONDecoder = JSONDecoder()) {
        self.session = session
        self.encoder = encoder
        self.decoder = decoder
    }
    
    public func get<T: Decodable>(_ url: URL) async throws(NetworkingError) -> T {
        let request = URLRequest(url: url)
        return try await perform(request)
    }
    
    public func get<T: Decodable>(_ url: URL, parameters: [String: String]) async throws(NetworkingError) -> T {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw NetworkingError.otherError(URLError(.badURL))
        }
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        
        guard let parameterizedURL = components.url else {
            throw NetworkingError.otherError(URLError(.badURL))
        }
        return try await get(parameterizedURL)
    }
    
    public func post<T: Encodable>(_ url: URL, body: T) async throws(NetworkingError) {
        do {
            var request = URLRequest(url: url)
            request.httpMethod = HTTPMethod.post.rawValue
            request.setJSONContentType()
            request.httpBody = try encoder.encode(body)
            
            let (_, response) = try await session.data(for: request)
            try validate(response)
        } catch {
            throw map(error)
        }
    }
}

// MARK: - Private Helpers

private extension NetworkService {
    func perform<T: Decodable>(_ request: URLRequest) async throws(NetworkingError) -> T {
        do {
            let (data, response) = try await session.data(for: request)
            try validate(response)
            return try decode(data)
        } catch {
            throw map(error)
        }
    }
    
    func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkingError.otherError(URLError(.badURL))
        }
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkingError.invalidStatusCode(httpResponse.statusCode)
        }
    }
    
    func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch let error as DecodingError {
            throw NetworkingError.decodingFailed(error)
        }
    }
    
    func map(_ error: Error) -> NetworkingError {
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

private extension URLRequest {
    mutating func setJSONContentType() {
        self.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }
}
