// Recreated April 15, 2025
// by Braden Hicks
import Fluent
import Vapor

struct RecipeWithIngredientsAndKeywords: Content {
    let id: Int?
    let link: String?
    let image_url: String?
    let total_time: Double?
    let cook_time: Double?
    let prep_time: Double?
    let recipe_name: String?
    let total_time_text: String?
    let cook_time_text: String?
    let prep_time_text: String?
    let likes: Int?
    let ingredients: [String]
    let keywords: [String]
    let instructions: [String]
    let instruction_step: [String]
}

extension RecipeWithIngredientsAndKeywords {
    struct Create: Content, Validatable {
        let link: String?
        let image_url: String?
        let total_time: Double?
        let cook_time: Double?
        let prep_time: Double?
        let recipe_name: String?
        let total_time_text: String?
        let cook_time_text: String?
        let prep_time_text: String?
        let likes: Int?
        let ingredients: [String]
        let keywords: [String]
        let instructions: [String]
        let instruction_step: [String]

        static func validations(_ validations: inout Validations) {
            validations.add("recipe_name", as: String.self, is: .count(1...), required: true)
            validations.add("ingredients", as: [String].self, is: .count(1...), required: true)
            // Add more validation rules as needed
        }
    }
}
