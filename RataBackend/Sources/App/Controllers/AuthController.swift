//import Vapor
//import Fluent
//
////struct AuthController: RouteCollection {
////    func boot(routes: RoutesBuilder) throws {
////        let authRoutes = routes.grouped("auth")
////        authRoutes.post("login", use: login)
////    }
////
////    func login(req: Request) async throws -> ProfileToken {
////        // 1. Decode the login request
////        let loginRequest = try req.content.decode(LoginRequest.self)
////
////        // 2. Find the profile by username
////        guard let profile = try await Profile.query(on: req.db)
////            .filter(\.$username == loginRequest.username)
////            .first() else {
////            throw Abort(.unauthorized, reason: "Invalid username or password")
////        }
////
////        // 3. Verify the password
////        try await req.password.async.verify(loginRequest.password, created: profile.password)
////
////        // 4. Generate a token
////        let tokenValue = [UInt8].random(count: 16).base64
////        let token = try ProfileToken(value: tokenValue, profileID: profile.requireID())
////
////        // 5. Save the token to the database
////        try await token.save(on: req.db)
////
////        return token
////    }
////}
////
////struct LoginRequest: Content {
////    let username: String
////    let password: String
////}
