//
//  LikedRecipe.swift
//  RataBackend
//
//  Created by Braden Hicks on 3/9/25.
//

import Fluent
import Vapor

final class LikedRecipe: Model, Content {
	static let schema = "user_favorites"
	
	@ID(custom: "id")
	var id: Int?

	@Parent(key: "profile_id")
	var profile: Profile

	@Parent(key: "recipe_id")
	var recipe: Recipe

	init() { }
	
	init(id: Int, profile_id: UUID, recipe_id: Int) {
		self.id = id
		self.$profile.id = profile_id
		self.$recipe.id = recipe_id
	}
}

