import Fluent
import Vapor

final class Recipe: Model, Content {
    static let schema = "recipes" // Name of the table in the database

    typealias IDValue = Int

    @ID(custom: "recipe_id") // Map to the `recipe_id` column
    var id: Int?

    @Field(key: "link")
    var link: String?

    @Field(key: "image_url")
    var image_url: String?

    @Field(key: "total_time")
    var total_time: Double?

    @Field(key: "cook_time")
    var cook_time: Double?

    @Field(key: "prep_time")
    var prep_time: Double?

    @Field(key: "recipe_name")
    var recipe_name: String?

    @Field(key: "total_time_text")
    var total_time_text: String?

    @Field(key: "cook_time_text")
    var cook_time_text: String?

    @Field(key: "prep_time_text")
    var prep_time_text: String?

    @Field(key: "likes")
    var likes: Int?
    
    @Children(for: \.$recipe)
    var ingredients: [Ingredient]
    
    @Children(for: \.$recipe)
    var keywords: [Keyword]
    
    @Children(for: \.$recipe)
    var instructions: [Instruction]

    init() { }

    init(
        id: Int? = nil,
        link: String? = nil,
        image_url: String? = nil,
        total_time: Double? = nil,
        cook_time: Double? = nil,
        prep_time: Double? = nil,
        recipe_name: String? = nil,
        total_time_text: String? = nil,
        cook_time_text: String? = nil,
        prep_time_text: String? = nil,
        likes: Int? = nil
    ) {
        self.id = id
        self.link = link
        self.image_url = image_url
        self.total_time = total_time
        self.cook_time = cook_time
        self.prep_time = prep_time
        self.recipe_name = recipe_name
        self.total_time_text = total_time_text
        self.cook_time_text = cook_time_text
        self.prep_time_text = prep_time_text
        self.likes = likes
    }
}
