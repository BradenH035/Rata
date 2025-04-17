//
//  Keyword.swift
//  RataBackend
//
//  Created by Braden Hicks on 2/9/25.
//

import Fluent
import Vapor

final class Keyword: Model, Content {
    static let schema = "keywords"
    
    @ID(custom: "keyword_id")
    var id: Int?
    
    @Parent(key: "recipe_id")
    var recipe: Recipe
    
    @Field(key: "keyword")
    var keyword: String
    
    init() { }
    
    init(id: Int? = nil, keyword: String, recipeID: Int) {
        self.id = id
        self.keyword = keyword
        self.$recipe.id = recipeID
    }
}
