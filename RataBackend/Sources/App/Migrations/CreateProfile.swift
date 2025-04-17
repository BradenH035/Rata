import Fluent

struct CreateProfile: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("profiles")
            .id()
            .field("username", .string, .required)
            .field("password", .string, .required)
            .unique(on: "username")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("profiles").delete()
    }
}
