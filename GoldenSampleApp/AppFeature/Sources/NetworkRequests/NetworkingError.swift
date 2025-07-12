import Foundation

// MARK: - Network Error

enum NetworkingError: LocalizedError {
    case encodingFailed(EncodingError)
    case decodingFailed(DecodingError)
    case invalidStatusCode(Int)
    case requestFailed(URLError)
    case otherError(Error)
    
    var errorDescription: String?    {
        switch self {
        case .encodingFailed(let error):
            return "Encoding failed: \(error)"
        case .decodingFailed(let error):
            return "Decoding failed: \(error)"
        case .invalidStatusCode(let code):
            return "Invalid status code: \(code)"
        case .requestFailed(let error):
            return "Request failed: \(error)"
        case .otherError(let error):
            return "Something went wrong: \(error)"
        }
    }
}
