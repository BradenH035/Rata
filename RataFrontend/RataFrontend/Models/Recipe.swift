//
//  Recipe.swift
//  Rata
//
//  Created by Braden Hicks on 1/31/25.
//

import Foundation
import SwiftData


@Model
final class RecipeModel {
    var recipe_id: Int?
    var recipe_name: String?
    var cook_time: Int?
    var likes: Int?
    var total_time_text: String?
    var total_time: Int?
    var prep_time: Int?
    var link: String?
    var image_url: String?
    var prep_time_text: String?
    var cook_time_text: String?
    var ingredients: [String]
    var keywords: [String]
    var instructions: [String]
    var instruction_step: [String]

    init(
        recipe_id: Int? = nil,
        recipe_name: String? = nil,
        cook_time: Int? = nil,
        likes: Int? = nil,
        total_time_text: String? = nil,
        total_time: Int? = nil,
        prep_time: Int? = nil,
        link: String? = nil,
        image_url: String? = nil,
        prep_time_text: String? = nil,
        cook_time_text: String? = nil,
        ingredients: [String] = [],
        keywords: [String] = [],
        instructions: [String] = [],
        instruction_step: [String] = []
    ) {
        self.recipe_id = recipe_id
        self.recipe_name = recipe_name
        self.cook_time = cook_time
        self.likes = likes
        self.total_time_text = total_time_text
        self.total_time = total_time
        self.prep_time = prep_time
        self.link = link
        self.image_url = image_url
        self.prep_time_text = prep_time_text
        self.cook_time_text = cook_time_text
        self.ingredients = ingredients
        self.keywords = keywords
        self.instructions = instructions
        self.instruction_step = instruction_step
    }
}


extension RecipeModel {
    func missingIngredientsCount(userIngredients: [String]) -> Int {
        ingredients.filter { !userIngredients.contains($0) }.count
    }
}

extension RecipeModel: CustomStringConvertible {
    var description: String {
        return "RecipeModel(id: \(recipe_id ?? -1), name: \(recipe_name ?? "-1"))"
    }
}



struct Recipe: Decodable {
    let id: Int?
    let recipe_name: String?
    let cook_time: Int?
    let likes: Int?
    let total_time_text: String?
    let total_time: Int?
    let prep_time: Int?
    let link: String?
    let image_url: String?
    let prep_time_text: String?
    let cook_time_text: String?
    let ingredients: [String]
    let keywords: [String]
    let instructions: [String]
    let instruction_step: [String]
}


struct RecipeLoader {
    
    func loadRecs() async throws -> ([Recipe], HTTPURLResponse) {
        let defaults = UserDefaults.standard
        let etag = defaults.string(forKey: "etag")
        
        var headers: [String:String] = ["Content-Type": "applications.json"]
        
        if let etag {
            headers["If-None-Match"] = etag
        }
        var request = URLRequest(url: Constants.Urls.recipes)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.allHTTPHeaderFields = headers
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
                
        let recipes = try! JSONDecoder().decode([Recipe].self, from: data)
        return (recipes, httpResponse)
    }
}

