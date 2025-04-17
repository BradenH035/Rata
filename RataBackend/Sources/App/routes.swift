import Fluent
import Vapor

func routes(_ app: Application) throws {
    //let authController = AuthController()
    //try app.register(collection: authController)

    // Routes for Recipes  
    app.get("recipes") { req async throws -> [RecipeWithIngredientsAndKeywords] in
        // Step 1: Fetch recipes with related data
        let recipes = try await Recipe.query(on: req.db)
            .with(\.$ingredients)
            .with(\.$keywords)
            .with(\.$instructions)
            .all()

        // Step 2: Transform the fetched recipes into the desired format
        return try recipes.map { recipe in	
       		// Step 3: Extract ingredients, keywords, and instructions
                let ingredients = recipe.ingredients.map { $0.ingredient }
                let keywords = recipe.keywords.map { $0.keyword }
                let temp = recipe.instructions.map { ($0.step_number, $0.instruction) }
                let sortedTemp = temp.sorted { $0.0 < $1.0 }
                
                let instructions: [String] = sortedTemp.map(\.1)
                let instruction_steps = sortedTemp.map { String($0.0) }

                // Step 4: Create a RecipeWithIngredientsAndKeywords object
                return RecipeWithIngredientsAndKeywords(
                    id: recipe.id,
                    link: recipe.link,
                    image_url: recipe.image_url,
                    total_time: recipe.total_time,
                    cook_time: recipe.cook_time,
                    prep_time: recipe.prep_time,
                    recipe_name: recipe.recipe_name,
                    total_time_text: recipe.total_time_text,
                    cook_time_text: recipe.cook_time_text,
                    prep_time_text: recipe.prep_time_text,
                    likes: recipe.likes,
                    ingredients: ingredients,
                    keywords: keywords,
                    instructions: instructions,
                    instruction_step: instruction_steps
                )
            }
    }
    
    app.get("recipes", ":recipe_name") { req async throws -> RecipeWithIngredientsAndKeywords in
        guard let recipe_name = req.parameters.get("recipe_name") else {
            throw Abort(.badRequest, reason: "Invalid or missing recipe name")
        }
        
        guard let recipe = try await Recipe.query(on: req.db)
            .filter(\.$recipe_name == recipe_name) // Filter by recipe_name
            .with(\.$ingredients)
            .with(\.$keywords)
            .with(\.$instructions)
            .first() // Fetch a single recipe
        else {
            throw Abort(.notFound, reason: "Recipe not found")
        }
        
        let ingredients = recipe.ingredients.map { $0.ingredient }
        let keywords = recipe.keywords.map { $0.keyword }
        let temp = recipe.instructions.map { ($0.step_number, $0.instruction) }
        let sortedTemp = temp.sorted { $0.0 < $1.0 }
        
        let instructions: [String] = sortedTemp.map(\.1)
        let instruction_steps = sortedTemp.map { String($0.0) }

        return RecipeWithIngredientsAndKeywords(
            id: recipe.id,
            link: recipe.link,
            image_url: recipe.image_url,
            total_time: recipe.total_time,
            cook_time: recipe.cook_time,
            prep_time: recipe.prep_time,
            recipe_name: recipe.recipe_name,
            total_time_text: recipe.total_time_text,
            cook_time_text: recipe.cook_time_text,
            prep_time_text: recipe.prep_time_text,
            likes: recipe.likes,
            ingredients: ingredients,
            keywords: keywords,
            instructions: instructions,
            instruction_step: instruction_steps
        )
    }
    
    func generateUniqueID<T:Model>(database: Database, retries: Int = 100, model: T.Type) -> EventLoopFuture<Int> where T.IDValue == Int {
        if retries <= 0 {
            return database.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Failed to generate unique ID")) // No more retries left
        }
        
        let randomID = Int.random(in: 1..<Int.max)

        // Check if the ID already exists in the database
        return model.query(on: database)
            .filter(\._$id == randomID)
            .first()
            .flatMap { existingRecipe in
                if existingRecipe == nil {
                    // ID is unique
                    return database.eventLoop.makeSucceededFuture(randomID)
                } else {
                    return generateUniqueID(database: database, retries: retries - 1, model: model)
                }

            }
    }
    
    
    /* Users will create a recipe that they want to add to database
     
     Note: it will have to go through approval (ensure no bad words, fix any typos, all required fields are included
     Users will see that their recipe is pending approval and receive a notification when it is approved
     ex: "CONGRATULATIONS! Your recipe __recipe_name__ was approved!
     They can see how many uses their recipes gets (track its likes and have unique access to the recipe)
     */
    
    app.post("recipes") { req async throws -> Response in
        try RecipeWithIngredientsAndKeywords.Create.validate(content: req)
        let create = try req.content.decode(RecipeWithIngredientsAndKeywords.Create.self)
        let recipeID = try await generateUniqueID(database: req.db, model: Recipe.self).get()
        
        var responses: [Response] = []
        
        
        let recipe = Recipe(
            id: recipeID,
            link: create.link,
            image_url: create.image_url,
            total_time: create.total_time,
            cook_time: create.cook_time,
            prep_time: create.prep_time,
            recipe_name: create.recipe_name,
            total_time_text: create.total_time_text,
            cook_time_text: create.cook_time_text,
            prep_time_text: create.prep_time_text,
            likes: create.likes
            )
        
        try await recipe.save(on: req.db)
        responses.append(try await recipe.encodeResponse(status: .created, for: req))
        
        for ingredient in create.ingredients {
            async let ingredientID = generateUniqueID(database: req.db, model: Ingredient.self).get()
            
            let newIngredient = Ingredient(
                id: try await ingredientID,
                ingredient: ingredient,
                recipeID: recipeID
            )
            try await newIngredient.save(on: req.db)
            responses.append(try await newIngredient.encodeResponse(status: .created, for: req))
        }

        
        // NEED TO CREATE AN ALGORITHM FOR FINDING KEYWORDS BASED ON USER ENTRY
        // Basically: Users should not have to add keywords, need script to autogenerate them based on the ingredients
        // Then we can use the code below
//        for keyword in create.keywords {
//            async let keywordID = generateUniqueID(database: req.db, model: Keyword.self).get()
//
//            let newKeyword = Keyword(
//                id: try await keywordID,
//                ingredient: keyword,
//                recipeID: recipeID
//            )
//            try await newKeyword.save(on: req.db)
//        }
        for (i, instruction) in create.instructions.enumerated() {
            async let instructionID = generateUniqueID(database: req.db, model: Instruction.self).get()
            
            let newInstruction = Instruction(
                id: try await instructionID,
                instruction: instruction,
                recipeID: recipeID,
                stepNumber: i + 1
            )
            try await newInstruction.save(on: req.db)
            responses.append(try await newInstruction.encodeResponse(status: .created, for: req))
        }

        // for testing purposes only
        for response in responses {
            if response.status != .created {
                return try await recipe.encodeResponse(status: .expectationFailed , for: req)
            }
        }
        
        return Response(status: .ok)
    }
    
    
    app.put("recipes", ":recipe_name", "likes") { req async throws -> Response in
        guard let recipeName = req.parameters.get("recipe_name") else {
            throw Abort(.badRequest, reason: "Missing recipe name")
        }

        struct LikeRequest: Content {
            let username: String
        }

        let likeRequest = try req.content.decode(LikeRequest.self)

        guard let recipe = try await Recipe.query(on: req.db)
            .filter(\.$recipe_name == recipeName)
            .first()
        else {
            throw Abort(.notFound, reason: "Recipe not found")
        }

        guard let profile = try await Profile.query(on: req.db)
            .filter(\.$username == likeRequest.username)
            .first()
        else {
            throw Abort(.notFound, reason: "Profile not found")
        }

        let alreadyLiked = try await LikedRecipe.query(on: req.db)
            .filter(\.$profile.$id == profile.requireID())
            .filter(\.$recipe.$id == recipe.requireID())
            .first() != nil
        print("AlreadyLiked? \(alreadyLiked)")
        if !alreadyLiked {
            recipe.likes! += 1
            try await recipe.save(on: req.db)

            let liked = LikedRecipe(
                id: try await generateUniqueID(database: req.db, model: LikedRecipe.self).get(),
                profile_id: try profile.requireID(),
                recipe_id: try recipe.requireID()
            )
            print("LikedRecipe Create: \(liked)")

            try await liked.save(on: req.db)
        }
        let alreadyLikedAfter = try await LikedRecipe.query(on: req.db)
            .filter(\.$profile.$id == profile.requireID())
            .filter(\.$recipe.$id == recipe.requireID())
            .first() != nil
        print(alreadyLikedAfter)

        struct LikeResponse: Content {
            let likes: Int
            let message: String
        }

        return try await LikeResponse(
            likes: recipe.likes!,
            message: alreadyLiked ? "Already liked" : "Recipe liked successfully"
        ).encodeResponse(for: req)
    }
    
    
    
    app.delete("recipes", ":recipe_name", "likes") { req async throws -> Response in
        guard let recipeName = req.parameters.get("recipe_name") else {
            throw Abort(.badRequest, reason: "Missing recipe name")
        }

        struct UnlikeRequest: Content {
            let username: String
        }

        let unlikeRequest = try req.content.decode(UnlikeRequest.self)

        guard let recipe = try await Recipe.query(on: req.db)
            .filter(\.$recipe_name == recipeName)
            .first()
        else {
            throw Abort(.notFound, reason: "Recipe not found")
        }

        guard let profile = try await Profile.query(on: req.db)
            .filter(\.$username == unlikeRequest.username)
            .first()
        else {
            throw Abort(.notFound, reason: "Profile not found")
        }

        // Check if already liked
        let likedRecord = try await LikedRecipe.query(on: req.db)
            .filter(\.$profile.$id == profile.requireID())
            .filter(\.$recipe.$id == recipe.requireID())
            .first()

        if let likedRecord = likedRecord {
            if recipe.likes! > 0 {
                recipe.likes! -= 1
            }
            try await recipe.save(on: req.db)

            try await likedRecord.delete(on: req.db)
        }

        struct UnlikeResponse: Content {
            let likes: Int
            let message: String
        }

        return try await UnlikeResponse(
                likes: recipe.likes!,
                message: "Recipe unliked successfully"
            ).encodeResponse(for: req)
    }
    
    // Users will not have delete access
    // They can have the option to remove their recipe from approval list (ex: typo in name, no longer wish to add)
    // but once it is posted it cannot be taken down
    // This function should rarely (if ever) be used - written 3/20/25 @ 12:24PM CT
    app.delete("recipes", ":recipe_name") { req async throws -> Response in

        guard let recipe_name = req.parameters.get("recipe_name") else {
            throw Abort(.badRequest, reason: "Invalid or missing recipe name")
        }
        
        guard let recipe = try await Recipe.query(on: req.db)
               .filter(\.$recipe_name == recipe_name)
               .first()
           else {
               throw Abort(.notFound, reason: "Recipe not found")
           }
        
        try await recipe.delete(on: req.db) // Should delete from ingredients and instructions (Cascading)
        let responseMessageJSON = ["message:", "Recipe successfully deleted"]
        return try Response(status: .ok, body: .init(data: JSONEncoder().encode(responseMessageJSON)))
        
    }
    

    
    app.get("profiles") { req async throws -> [Profile] in
        let profiles = try await Profile.query(on: req.db)
            .with(\.$liked_recipes)
            .all()
        return profiles
    }
    
    app.get("profiles", ":username") { req async throws -> FullProfile in
        guard let username = req.parameters.get("username") else {
            throw Abort(.badRequest, reason: "Missing username")
        }
                
        guard let profile = try await Profile.query(on: req.db)
            .filter(\.$username == username)
            .with(\.$liked_recipes)
            .first()
        else {
            throw Abort(.notFound, reason: "Profile not in database")
            }
        
        let liked_recipes = profile.liked_recipes.compactMap { $0.$recipe.id }
        return FullProfile(
            username: profile.username,
            password: profile.password,
            liked_recipes: liked_recipes,
            email: profile.email
        )
    }
    
    
    app.post("profiles") { req async throws -> Response in
        try Profile.Create.validate(content: req)
        let create = try req.content.decode(Profile.Create.self)
        
        let profile = try Profile(
            username: create.username,
            passwordHash: Bcrypt.hash(create.password),
            email: create.email
        )
        
        try await profile.save(on: req.db)
        return try await profile.encodeResponse(status: .created, for: req)
    }
    
        
        
    app.delete("profiles", ":username") { req async throws -> Response in
        guard let username = req.parameters.get("username") else {
            throw Abort(.badRequest, reason: "Missing username")
        }
        guard let profile = try await Profile.query(on: req.db)
            .filter(\.$username == username)
            .with(\.$liked_recipes)
            .first()
        else {
            throw Abort(.notFound, reason: "Profile not found")
        }
        
        try await profile.delete(on: req.db)
        let responseMessageJSON = ["message:", "Profile successfully deleted"]
        return try Response(status: .ok, body: .init(data: JSONEncoder().encode(responseMessageJSON)))
        
    }
    
}



/// code for making a likedRecipe

// This should be empty
//for recipe in create.liked_recipes {
//    async let likedRecipeID = generateUniqueID(database: req.db, model: LikedRecipe.self).get()
//    
//    let newLikedRecipe = LikedRecipe(
//        id: try await likedRecipeID,
//        profile_id: profile.id!,
//        recipe_id: recipe.id!
//    )
//    try await newLikedRecipe.save(on: req.db)
//    responses.append(try await newLikedRecipe.encodeResponse(status: .created, for: req))
//}
//




/// code for TokenAuthentication if needed

//    let tokenProtected = app.grouped(ProfileToken.authenticator())
//    tokenProtected.get("me") { req -> Profile in
//        try req.auth.require(Profile.self)
//    }
//
//    let tokenMiddleware = ProfileToken.authenticator()
//    let protectedRoutes = app.grouped(tokenMiddleware)
//    protectedRoutes.get("my-profile") { req async throws -> FullProfile in
//        // 1. Get the authenticated user
//        let profile = try req.auth.require(Profile.self)
//
//        // 2. Fetch the profile for the authenticated user
//        guard let fullProfile = try await Profile.query(on: req.db)
//            .filter(\.$id == profile.id!)
//            .with(\.$liked_recipes) // Eager load the liked_recipes relationship
//            .first() else {
//            throw Abort(.notFound, reason: "Profile not found")
//        }
//
//        // 3. Extract liked recipe IDs
//        let liked_recipes = profile.liked_recipes.map { $0.$recipe.id }
//
//        // 4. Return the FullProfile
//        return FullProfile(
//            id: fullProfile.id!,
//            username: fullProfile.username,
//            liked_recipes: liked_recipes,
//            email: fullProfile.email
//        )
//    }
    
