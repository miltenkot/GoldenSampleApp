import Foundation

struct Post: Codable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

struct Comment: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let body: String
}

struct Photo: Codable {
    let albumId: Int
    let id: String
    let title: String
    let url: String
    let thumbnailUrl: String
}

struct EmptyPhoto: Codable {}
