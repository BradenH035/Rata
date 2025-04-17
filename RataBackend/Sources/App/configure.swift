import Fluent
import FluentPostgresDriver
import Vapor


struct ShutdownHandler: LifecycleHandler {
    func willShutdown(_ app: Application) {
        app.logger.info("Application is shutting down...")
        // Add cleanup logic here
    }
}

public func configure(_ app: Application) throws {
    app.logger.info("Staring application configuration...")

    // Get database credentials from environment variables
    let dbHostname = Environment.get("DATABASE_HOSTNAME") ?? "localhost"
    let dbUsername = Environment.get("DATABASE_USERNAME") ?? "bradenhicks"
    let dbPassword = Environment.get("DATABASE_PASSWORD") ?? "Basket2Ball"
    let dbName = Environment.get("DATABASE_NAME") ?? "rata"

    // Configure PostgreSQL database
    app.databases.use(.postgres(
        hostname: dbHostname,
        username: dbUsername,
        password: dbPassword,
        database: dbName
    ), as: .psql)

    // Add migrations
    //app.migrations.add(CreateProfile())
    //app.migrations.add(CreateProfileToken())

    try app.autoMigrate().wait()
    app.logger.info("Migrations completed.")

    // Register routes
    try routes(app)
    app.logger.info("Routes registered.")
    
    // Handle graceful shutdown
    app.lifecycle.use(ShutdownHandler())
    
    app.logger.info("App has successfully shut down")
}
