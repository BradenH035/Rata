//
//  Recreated Ingredient.swift
//  RataBackend
//
//  Created by Braden Hicks on 4/15/25.
//


import Fluent
import Vapor

final class Ingredient: Model, Content {
    static let schema = "ingredients"
    
    @ID(custom: "ingredient_id")
    var id: Int?
    
    @Parent(key: "recipe_id")
    var recipe: Recipe
    
    @Field(key: "ingredient")
    var ingredient: String
    
    init() { }
    
    init(id: Int? = nil, ingredient: String, recipeID: Int) {
        self.id = id
        self.ingredient = ingredient
        self.$recipe.id = recipeID
    }
}

