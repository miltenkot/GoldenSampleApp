import Foundation

// MARK: - Network Error

public enum NetworkingError: LocalizedError {
    case encodingFailed(EncodingError)
    case decodingFailed(DecodingError)
    case invalidStatusCode(Int)
    case requestFailed(URLError)
    case otherError(Error)
    
    public var errorDescription: String?    {
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

extension NetworkingError: Equatable {
    public static func == (lhs: NetworkingError, rhs: NetworkingError) -> Bool {
        switch (lhs, rhs) {
        case (.encodingFailed(let lhsError), .encodingFailed(let rhsError)):
            return "\(lhsError)" == "\(rhsError)"
        case (.decodingFailed(let lhsError), .decodingFailed(let rhsError)):
            return "\(lhsError)" == "\(rhsError)"
        case (.invalidStatusCode(let lhsCode), .invalidStatusCode(let rhsCode)):
            return lhsCode == rhsCode
        case (.requestFailed(let lhsError), .requestFailed(let rhsError)):
            return lhsError.code == rhsError.code
        case (.otherError(let lhsError), .otherError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
