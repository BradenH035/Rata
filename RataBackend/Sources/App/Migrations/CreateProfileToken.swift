import Fluent

struct CreateProfileToken: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("profile_tokens")
            .id()
            .field("value", .string, .required)
            .field("profile_id", .uuid, .required, .references("profiles", "id"))
            .unique(on: "value")
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("profile_tokens").delete()
    }
}
