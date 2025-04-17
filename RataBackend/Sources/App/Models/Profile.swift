import Vapor
import Fluent

final class Profile: Model, Authenticatable, Content {
    static let schema = "profiles"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "username")
    var username: String

    @Field(key: "password")
    var password: String
    
    @Field(key: "email")
    var email: String

    @Children(for: \.$profile)
    var liked_recipes: [LikedRecipe]
    
    init() { }

    init(username: String, passwordHash: String, email: String) {
        self.username = username
        self.password = passwordHash
        self.email = email
    }

    func hashPassword(_ password: String) throws {
        self.password = try Bcrypt.hash(password)
    }
}

extension Profile {
    struct Create: Content {
        var username: String
        var email: String
        var password: String
    }
}

extension Profile.Create: Validatable {
    static func validations(_ validations: inout Validations) {
        validations.add("username", as: String.self, is: !.empty)
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(8...))
    }
}

extension Profile: ModelAuthenticatable {
    static let usernameKey = \Profile.$email
    static let passwordHashKey = \Profile.$password

    func verify(password: String) throws -> Bool {
        try Bcrypt.verify(password, created: self.password)
    }
}


struct ProfileData: Content {
    let username: String
    let password: String
    let email: String
}

