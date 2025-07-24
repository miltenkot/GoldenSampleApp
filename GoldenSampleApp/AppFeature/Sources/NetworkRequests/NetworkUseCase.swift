//
//  NetworkUseCase.swift
//  AppFeature
//
//  Created by Bartlomiej Lanczyk on 19/07/2025.
//

import Foundation
import SwiftUI
import NetworkService

@MainActor
protocol NetworkUseCaseProtocol {
    func fetchPost() async throws(NetworkingError) -> Post?
    func fetchComments() async throws(NetworkingError) -> [Comment]
    func postValidPhoto() async throws(NetworkingError)
    func postInvalidPhoto() async throws(NetworkingError)
}

@MainActor
final class NetworkUseCase: NetworkUseCaseProtocol {
    private let networkService: NetworkServiceProtocol
    
    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }
    
    func fetchPost() async throws(NetworkingError) -> Post? {
        try await networkService.get(URL(string: Constants.postURL)!)
    }
    
    func fetchComments() async throws(NetworkingError) -> [Comment] {
        return try await networkService.get(
             URL(string: Constants.commentsURL)!,
             parameters: [Constants.postIdParameter: Constants.postIdValue]
         )
    }
    
    func postValidPhoto() async throws(NetworkingError) {
        try await networkService.post(
            URL(string: Constants.photosURL)!,
            body: Photo(albumId: 1, id: "Id", title: "title", url: "url", thumbnailUrl: "thumbnailUrl")
        )
    }
    
    func postInvalidPhoto() async throws(NetworkingError) {
        try await networkService.post(
            URL(string: Constants.wrongPhotosURL)!,
            body: EmptyPhoto()
        )
    }
}

extension NetworkUseCase {
    
    // MARK: - Constants

    private enum Constants {
        static let postURL = "https://jsonplaceholder.typicode.com/posts/1"
        static let commentsURL = "https://jsonplaceholder.typicode.com/comments"
        static let photosURL = "https://jsonplaceholder.typicode.com/photos"
        static let wrongPhotosURL = "https://jsonplaceholder.typicode.com/wrongphotos"
        static let postIdParameter = "postId"
        static let postIdValue = "1"
    }
}
