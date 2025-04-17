@testable import App
import VaporTesting
import Testing
import Fluent



@Suite("App Tests with DB", .serialized)
struct AppTests {
    private func withApp(_ test: (Application) async throws -> ()) async throws {
        let app = try await Application.make(.testing)
        do {
            try await configure(app)
            try await app.autoMigrate()
            try await test(app)
            try await app.autoRevert()
        }
        catch {
            try? await app.autoRevert()
            try await app.asyncShutdown()
            throw error
        }
        try await app.asyncShutdown()
    }
    
    @Test("Test Hello World Route")
    func helloWorld() async throws {
        try await withApp { app in
            try await app.testing().test(.GET, "profiles", afterResponse: { res async in
                #expect(res.status == .ok)
            })
        }
    }
    
    
    @Test("Test Create, Find, and Delete User")
    func testProfileLifecycle() async throws {
        try await withApp { app in
            var username: String?
            
            // Step 1: Create a Profile
            try await app.testing().test(.POST, "profiles") { req in
                try req.content.encode([
                    "username": "Vapor",
                    "password": "secret42",
                    "email": "test@vapor.codes",
                    ])
            } afterResponse: { res async in
                print("Create Response Status: \(res.status)")
                #expect(res.status == .created)
                
                let json = try? res.content.decode([String: String].self)
                username = json?["username"]
                #expect(username != nil) // Ensure ID is returned
            }
            
            // Ensure we have a valid profileID
            guard let username else { throw Abort(.internalServerError, reason: "Profile's username is nil") }

            // Step 2: Retrieve the Profile
            try await app.testing().test(.GET, "profiles/\(username)") { res async in
                print("Find Response Status: \(res.status)")
                #expect(res.status == .ok)
                
                let profile = try? res.content.decode(Profile.self)
                #expect(profile?.username == username)
            }


            // Step 3: Delete the Profile
            try await app.testing().test(.DELETE, "profiles/\(username)") { res async in
                print("Delete Response Status: \(res.status)")
                #expect(res.status == .ok)
            }

            // Step 4: Verify Profile is Deleted
            try await app.testing().test(.GET, "profiles/\(username)") { res async in
                print("Find After Delete Response Status: \(res.status)")
                #expect(res.status == .notFound) // Should be gone
            }
        }
    }
    
    
    @Test("Recipe Routes")
    func testRecipeRoutes() async throws {
        try await withApp { app in
            // Test full recipe databse GET route
            try await app.testing().test(.GET, "recipes", afterResponse: { res async in
                print("Full Recipe Database Route GET Status: \(res.status)")
                #expect(res.status == .ok)
            })
            
            
            // Test Specific Recipe GET Request
            let sampleID = 2943 // Recipe: Hot Milk Punch
            let sampleRecipeName = "Hot Milk Punch"
            // Note: when manually passing cURL requests, write like: "Hot%20Milk%20Punch"
            // %20 --> URL encoded to space character
            
            try await app.testing().test(.GET, "recipes/\(sampleRecipeName)", afterResponse: { res async in
                print("Specific Recipe Route GET Status: \(res.status)")
                #expect(res.status == .ok)
            })
            
            let recipeToAdd = RecipeWithIngredientsAndKeywords(
                id: 0,
                link: "https://www.loveandlemons.com/grilled-cheese/",
                image_url: "https://cdn.loveandlemons.com/wp-content/uploads/2023/01/grilled-cheese-sandwich.jpg",
                total_time: 10.0,
                cook_time: 5.0,
                prep_time: 5.0,
                recipe_name: "RemoveMe",
//                total_time_text: "10 mins",
//                cook_time_text: "5 mins",
//                prep_time_text: "5 mins",
//                likes: 0,
                total_time_text: nil,
                cook_time_text: nil,
                prep_time_text: nil,
                likes: 0, // Need to make this 0, can't be nil
                ingredients: ["2 slices sourdough bread",
                              "Mayonnaise",
                              "Dijon mustard",
                              "1 to 2 ounces grated sharp cheddar cheese, depending on the size of your bread",
                              "1 to 2 ounces grated Gruyère or raclette cheese, depending on the size of your bread",
                              "Butter, for the pan"],
                keywords: ["sourdough", "sourdough bread", "bread", "mayonnaise", "mayo", "mustard",
                           "cheese", "cheddar", "gruyere", "raclette", "cheddar cheese", "dijon", "dijon mustard", "butter"],
                instructions: [
                    "Place the bread slices on a cutting board and spread the top side with a thin layer of mayo. Flip one slice of bread and spread its other side with Dijon mustard. Layer the cheddar and Gruyère or Raclette cheeses on top of the mustard, then place the other slice of bread on top of the cheese, mayo side out.",
                    "Heat a nonstick or cast-iron skillet over medium-low heat and melt enough butter in the bottom of the pan to coat it. Place the sandwich in the pan, cover, and cook for 2 to 3 minutes, or until the bottom slice of bread is golden brown and crisp. Flip, replace the lid, and cook until the other slice of bread is golden brown and the cheese is melted, 1 to 3 minutes. Reduce the heat to low if the bread is getting too brown before the cheese is fully melted.",
                    "Slice and serve."],
                instruction_step: ["1", "2", "3"]
            )
            
            // Test POST route
            try await app.testing().test(.POST, "recipes", beforeRequest: { req in
                try req.content.encode(recipeToAdd)                
            }, afterResponse: { res in
                print("Specific Recipe Route POST - Status: \(res.status)")
                #expect(res.status == .ok)
                }
            )
            let recipeToDelete = "RemoveMe"
            
            // Test DELETE route
            try await app.testing().test(.DELETE, "recipes/\(recipeToDelete)") { res in
                print("Specific Recipe Route DELETE - Status: \(res.status)")
                #expect(res.status == .ok)
            }
            
            
            // Make sure it was succesfully deleted
            try await app.testing().test(.GET, "recipes/\(recipeToDelete)", afterResponse: { res async in
                print("Specific Recipe Route GET Status: \(res.status)")
                #expect(res.status == .notFound)
            })
            
            
        }

    }
    
    
    @Test("Like/Unlike")
    func testLikeRoutes() async throws {
        try await withApp { app in
            let recipeName = "Grilled Cheese"
            var username: String?
            var numLikes: Int?
            
            // Create a new profile
            try await app.testing().test(.POST, "profiles") { req in
                try req.content.encode([
                    "username": "sampleUser",
                    "password": "secret42",
                    "email": "test@vapor.codes"
                ])
            } afterResponse: { res async in
                print("Create Response Status: \(res.status)")
                #expect(res.status == .created)
                
                let json = try? res.content.decode([String: String].self)
                username = json?["username"]
                #expect(username != nil) // Ensure ID is returned
            }
            
            try await app.testing().test(.PUT, "recipes/\(recipeName)/likes", beforeRequest: { req in
                try req.content.encode(["username": username!])
            }, afterResponse: { res async in
                print("Testing Like Route PUT Method: \(res.status)")
                #expect(res.status == .ok)
            })
            
            // make sure recipes "likes" counter has increased
            try await app.testing().test(.GET, "recipes/\(recipeName)", afterResponse: { res async in
                let recipe = try? res.content.decode(RecipeWithIngredientsAndKeywords.self)
                numLikes = recipe!.likes!
                print("Number of Likes: \(numLikes ?? -1)")
                #expect(numLikes == 1)
            })
            
            try await app.testing().test(.DELETE, "recipes/\(recipeName)/likes", beforeRequest: { req in
                try req.content.encode(["username": username!])
            }, afterResponse: { res async in
                print("Testing Like Route DELETE Method: \(res.status)")
                #expect(res.status == .ok)
            })
                              
            // Ensure "likes" counter has been successfully decremented
            try await app.testing().test(.GET, "recipes/\(recipeName)", afterResponse: { res async in
                let recipe = try? res.content.decode(RecipeWithIngredientsAndKeywords.self)
                numLikes = recipe!.likes!
                #expect(numLikes == 0)
            })
            
            // Remove the temporary Profile
            try await app.testing().test(.DELETE, "profiles/\(username!)") { res async in
                print("Delete Profile Response Status: \(res.status)")
                #expect(res.status == .ok)
            }
                                         
        }
    }
        
}
