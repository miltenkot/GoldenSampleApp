import Testing
import Foundation

struct HTTPClientTransportTestSetupTrait: TestTrait, TestScoping {
    func provideScope(
        for test: Test, testCase: Test.Case?,
        performing function: @Sendable () async throws -> Void
    ) async throws {
        // Clear handler before test
        await MockURLProtocol.requestHandlerStorage.clearHandler()

        // Execute the test
        try await function()

        // Clear handler after test
        await MockURLProtocol.requestHandlerStorage.clearHandler()
    }
}

extension Trait where Self == HTTPClientTransportTestSetupTrait {
    static var httpClientTransportSetup: Self { Self() }
}

extension URLRequest {
    func readBody() -> Data? {
        if let httpBodyData = self.httpBody {
            return httpBodyData
        }

        guard let bodyStream = self.httpBodyStream else { return nil }
        bodyStream.open()
        defer { bodyStream.close() }

        let bufferSize: Int = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }

        var data = Data()
        while bodyStream.hasBytesAvailable {
            let bytesRead = bodyStream.read(buffer, maxLength: bufferSize)
            data.append(buffer, count: bytesRead)
        }
        return data
    }
}
