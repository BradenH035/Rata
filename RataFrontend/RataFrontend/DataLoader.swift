//
//  TempLoader.swift
//  Rata
//
//  Created by Braden Hicks on 2/3/25.
//

import Foundation
import SwiftData

struct DataImporter {
    let context: ModelContext
    let recipeLoader: RecipeLoader
    let profileLoader: ProfileLoader
    let profile: Profile
    
    init(profile: Profile, context: ModelContext, recipeLoader: RecipeLoader, profileLoader: ProfileLoader) {
            self.profile = profile
            self.context = context
            self.recipeLoader = recipeLoader
            self.profileLoader = profileLoader
    }
    
    
    @MainActor
    func importData(username: String) async throws {
        let (recipes, httpResponse_recipes) = try await recipeLoader.loadRecs() // GET all recipes
        
        switch httpResponse_recipes.statusCode {
        case 200: // 200 = OK, "Request Succeeded"
            try deleteAllRecipes()
            if !recipes.isEmpty {
                recipes.forEach { recipe in
                    let recipeModel = RecipeModel(
                        recipe_id: recipe.id,
                        recipe_name: recipe.recipe_name,
                        cook_time: recipe.cook_time,
                        likes: recipe.likes,
                        total_time_text: recipe.total_time_text,
                        total_time: recipe.total_time,
                        prep_time: recipe.prep_time,
                        link: recipe.link,
                        image_url: recipe.image_url,
                        prep_time_text: recipe.prep_time_text,
                        cook_time_text: recipe.cook_time_text,
                        ingredients: recipe.ingredients,
                        keywords: recipe.keywords,
                        instructions: recipe.instructions,
                        instruction_step: recipe.instruction_step
                    )
                    context.insert(recipeModel)
                    
                }
            }
            let profileModel = ProfileModel(
                username: profile.username,
                liked_recipes: profile.liked_recipes
                )
            context.insert(profileModel)
            
        default:
            break
        }
    }
    
    @MainActor
    private func deleteAllRecipes() throws {
        let descriptor = FetchDescriptor<RecipeModel>()
        let recipes = try context.fetch(descriptor)
        if recipes.isEmpty { return }
        
        for recipe in recipes {
            context.delete(recipe)
        }
        try context.save() // Save the context to persist the changes
    }
}
