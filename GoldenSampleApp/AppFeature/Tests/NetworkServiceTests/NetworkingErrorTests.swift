import Testing
import Foundation
@testable import NetworkService

@Suite("NetworkingError Tests")
struct NetworkingErrorTests {

    // MARK: - errorDescription Tests

    @Test("errorDescription for encodingFailed")
    func errorDescription_encodingFailed() {
        let originalError = EncodingError.invalidValue("value", .init(codingPath: [], debugDescription: "debug"))
        let networkingError = NetworkingError.encodingFailed(originalError)
        #expect(networkingError.errorDescription?.contains("Encoding failed:") == true)
    }

    @Test("errorDescription for decodingFailed")
    func errorDescription_decodingFailed() {
        let originalError = DecodingError.keyNotFound(CodingKeys.id, .init(codingPath: [], debugDescription: "missing id"))
        let networkingError = NetworkingError.decodingFailed(originalError)
        #expect(networkingError.errorDescription?.contains("Decoding failed:") == true)
    }

    @Test("errorDescription for invalidStatusCode")
    func errorDescription_invalidStatusCode() {
        let networkingError = NetworkingError.invalidStatusCode(401)
        #expect(networkingError.errorDescription == "Invalid status code: 401")
    }

    @Test("errorDescription for requestFailed")
    func errorDescription_requestFailed() {
        let originalError = URLError(.cancelled)
        let networkingError = NetworkingError.requestFailed(originalError)

        #expect(networkingError.errorDescription?.contains("Request failed") == true)
        #expect(networkingError.errorDescription?.contains("-999") == true)
    }

    @Test("errorDescription for otherError")
    func errorDescription_otherError() {
        struct CustomTestError: Error, LocalizedError {
            var errorDescription: String? { "A custom test error occurred." }
        }
        let originalError = CustomTestError()
        let networkingError = NetworkingError.otherError(originalError)
        #expect(networkingError.errorDescription?.contains("Something went wrong:") == true)
    }

    // MARK: - Equatable Conformance Tests

    @Test("Equatable: encodingFailed comparison")
    func equatable_encodingFailed() {
        let error1 = NetworkingError.encodingFailed(EncodingError.invalidValue("val1", .init(codingPath: [], debugDescription: "desc1")))
        let error2 = NetworkingError.encodingFailed(EncodingError.invalidValue("val1", .init(codingPath: [], debugDescription: "desc1")))
        let error3 = NetworkingError.encodingFailed(EncodingError.invalidValue("val2", .init(codingPath: [], debugDescription: "desc2")))
        
        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    @Test("Equatable: decodingFailed comparison")
    func equatable_decodingFailed() {
        let error1 = NetworkingError.decodingFailed(DecodingError.keyNotFound(CodingKeys.id, .init(codingPath: [], debugDescription: "missing id")))
        let error2 = NetworkingError.decodingFailed(DecodingError.keyNotFound(CodingKeys.id, .init(codingPath: [], debugDescription: "missing id")))
        let error3 = NetworkingError.decodingFailed(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "corrupted data")))

        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    @Test("Equatable: invalidStatusCode comparison")
    func equatable_invalidStatusCode() {
        let error1 = NetworkingError.invalidStatusCode(404)
        let error2 = NetworkingError.invalidStatusCode(404)
        let error3 = NetworkingError.invalidStatusCode(500)

        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    @Test("Equatable: requestFailed comparison")
    func equatable_requestFailed() {
        let error1 = NetworkingError.requestFailed(URLError(.cancelled))
        let error2 = NetworkingError.requestFailed(URLError(.cancelled))
        let error3 = NetworkingError.requestFailed(URLError(.timedOut))

        #expect(error1 == error2)
        #expect(error1 != error3)
    }

    @Test("Equatable: otherError comparison")
    func equatable_otherError() {
        struct MockError1: Error, LocalizedError { var errorDescription: String? { "Error One" } }
        struct MockError2: Error, LocalizedError { var errorDescription: String? { "Error One" } } // Same description
        struct MockError3: Error, LocalizedError { var errorDescription: String? { "Error Two" } }
        
        let errorA = NetworkingError.otherError(MockError1())
        let errorB = NetworkingError.otherError(MockError2())
        let errorC = NetworkingError.otherError(MockError3())

        #expect(errorA == errorB) // Should be equal based on localizedDescription
        #expect(errorA != errorC)
    }

    @Test("Equatable: different error types are not equal")
    func equatable_differentTypes() {
        let error1 = NetworkingError.invalidStatusCode(404)
        let error2 = NetworkingError.decodingFailed(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "")))

        #expect(error1 != error2)
    }
}

// Helper struct for DecodingError.keyNotFound
private struct CodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { self.stringValue = String(intValue); self.intValue = intValue }

    static let id = CodingKeys(stringValue: "id")!
}
