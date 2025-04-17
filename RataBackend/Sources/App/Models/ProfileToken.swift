import Vapor
import Fluent

final class ProfileToken: Model {
    
    static let schema = "profile_tokens"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "value")
    var value: String

    @Parent(key: "profile_id")
    var profile: Profile

    @Timestamp(key: "expires_at", on: .delete)
    var expiresAt: Date?

    init() { }

    init(value: String, profileID: UUID, expiresAt: Date? = nil) {
        self.id = id
        self.value = value
        self.$profile.id = profileID
        self.expiresAt = expiresAt
    }
}

extension ProfileToken: ModelTokenAuthenticatable{
    
    typealias User = Profile
    typealias Token = ProfileToken

    static let valueKey = \ProfileToken.$value
    static let userKey = \ProfileToken.$profile

    var isValid: Bool {
        // Add expiration check if needed
        // expiresAt.map { $0 > Date() } ?? true
        true
    }
}
