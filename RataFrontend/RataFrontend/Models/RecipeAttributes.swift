//
//  RecipeAttributes.swift
//  RataFrontend
//
//  Created by Braden Hicks on 4/19/25.
//
//  Currently unused

struct Instruction: Codable {
    let instruction: String
}

struct Ingredient: Codable {
    let ingredient: String
}

struct InstructionStep: Codable {
    let instruction_step: String
}

struct Keyword: Codable {
    let keyword: String
}

struct LikedRecipe: Codable {
    let liked_recipe_id: Int
}
