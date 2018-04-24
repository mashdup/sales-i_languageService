import FluentMySQL
import Vapor

/// Called before your application initializes.
///
/// https://docs.vapor.codes/3.0/getting-started/structure/#configureswift
public func configure(
    _ config: inout Config,
    _ env: inout Environment,
    _ services: inout Services
) throws {
    /// Register providers first
    try services.register(FluentMySQLProvider())

    /// Register routes to the router
    let router = EngineRouter.default()
    try routes(router)
    services.register(router, as: Router.self)

    /// Register middleware
    var middlewares = MiddlewareConfig() // Create _empty_ middleware config
    /// middlewares.use(FileMiddleware.self) // Serves files from `Public/` directory
    middlewares.use(DateMiddleware.self) // Adds `Date` header to responses
    middlewares.use(ErrorMiddleware.self) // Catches errors and converts to HTTP response
    services.register(middlewares)

    
//    let mysql: MySQLDatabase
    let db_hostname = Environment.get("DATABASE_HOSTNAME") ?? "127.0.0.1"
    let db_user = Environment.get("DATABASE_USER") ?? "root"
    let db_password = Environment.get("DATABASE_PASSWORD") ?? "root"
    let db_database = Environment.get("DATABASE_DB") ?? "languageService"
    
    let mysql = MySQLDatabase(config: MySQLDatabaseConfig(hostname: db_hostname,port :3306, username: db_user, password: db_password, database: db_database))
//    if env.isRelease {
//        mysql = MySQLDatabase(config: MySQLDatabaseConfig(hostname: "localhost", username: "vapor", password: "password", database: "vapor"))
//    } else {
//      let mysql = MySQLDatabase(config: MySQLDatabaseConfig(hostname: "127.0.0.1", port: 3306, username: "root", password: "root", database: "languageService"));
//
//    }
    
    
    var databases = DatabaseConfig()

    databases.add(database: mysql, as: .mysql)
    services.register(databases)

    /// Configure migrations
    var migrations = MigrationConfig()
    migrations.add(model: Translation.self, database: .mysql)
    migrations.add(model: Language.self, database: .mysql)
    services.register(migrations)

//    let serverConfig = EngineServerConfig(hostname: "localhost", port: 8080, backlog: 256, workerCount: ProcessInfo.processInfo.activeProcessorCount, maxBodySize: 1_000_0000, reuseAddress: true, tcpNoDelay: true)
//    services.register(serverConfig)
//    
}
