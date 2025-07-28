import FactoryKit
import NetworkService

extension Container {
    var networkUseCase: Factory<NetworkUseCaseProtocol> {
        Factory(self) { @MainActor in NetworkUseCase() }
    }
    
    var networkService: Factory<NetworkServiceProtocol> {
        Factory(self) { @MainActor in NetworkService() }
    }
}
