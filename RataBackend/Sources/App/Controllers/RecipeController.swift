import Vapor
import Fluent

final class RecipeController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("recipes", use: index)  // Endpoint for fetching recipes
    }

    func index(req: Request) throws -> EventLoopFuture<Response> {
        return Recipe.query(on: req.db).all().map { recipes in
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]  // Prevent "\/"

            let data = try! encoder.encode(recipes)
            let response = Response()
            response.body = .init(data: data)
            response.headers.replaceOrAdd(name: .contentType, value: "application/json")
            return response
        }
    }
}
