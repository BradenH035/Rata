//
//  Untitled.swift
//  RataBackend
//
//  Created by Braden Hicks on 2/11/25.
//

import Fluent
import Vapor

final class Instruction: Model, Content {
    static let schema = "instructions"
    
    @ID(custom: "instruction_id")
    var id: Int?
    
    @Parent(key: "recipe_id")
    var recipe: Recipe
    
    @Field(key: "instruction")
    var instruction: String
    
    @Field(key: "step_number")
    var step_number: Int
    
    init() { }
    
    init(id: Int? = nil, instruction: String, recipeID: Int, stepNumber: Int) {
        self.id = id
        self.instruction = instruction
        self.$recipe.id = recipeID
        self.step_number = stepNumber
        
    }
}


 
