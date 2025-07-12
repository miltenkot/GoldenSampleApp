import Foundation

struct Post: Decodable {
    let userId: Int
    let id: Int
    let title: String
    let body: String
}

struct Comment: Decodable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let body: String
}

struct Photo: Encodable {
    let albumId: Int
    let id: String
    let title: String
    let url: String
    let thumbnailUrl: String
}

struct EmptyPhoto: Encodable {}
