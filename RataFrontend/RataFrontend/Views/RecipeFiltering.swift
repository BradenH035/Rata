//
//  RecipeFiltering 2.swift
//  Rata
//
//  Created by Braden Hicks on 2/9/25.
//
import Foundation
import SwiftUI
import SwiftData

struct RecipeCard: View {
    let recipe: RecipeModel

    
    var body: some View {
        ZStack {
            AsyncImage(url: URL(string: recipe.image_url!))
                .scaledToFill()
                .frame(width: 150, height: 125)
                .clipped()
                .opacity(0.9)

            VStack {
                    Spacer()
                    Text(recipe.recipe_name!)
                        .foregroundStyle(Color.white)
                        .font(.body)
                        .bold()
                        .lineLimit(2) // Keeps it to two lines
                        .minimumScaleFactor(0.5) // Scales down font if it's too long
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.horizontal, .bottom], 6)
                }
                .frame(width: 150, height: 125)
        }
    }
}



struct RecipeFiltering: View {
    @Environment(\.modelContext) private var modelContext
    @State private var ingredients: [String] = []
    @State private var errorMessage: String?
    var username: String
    // Use @Query to fetch all recipes
    @Query var allRecipes: [RecipeModel]
    var body: some View {
        NavigationStack{
            VStack {
                Form {
                    ForEach(0..<ingredients.count, id: \.self) { index in
                        TextField("Enter ingredient", text: $ingredients[index])
                    }
                }
                Button(action: {
                    ingredients.append("")
                }) {
                    Label("Add more ingredients", systemImage: "plus")
                }
                .padding()
                
                NavigationLink(destination: RecipeView2(username: username, ingredients: $ingredients, allRecipes: Array(allRecipes))) {
                    Text("Generate Recipes")
                }
            }
            .navigationTitle("Enter Ingredients")

        } //end of navigation stack
    } // end of body
}

struct RecipeView2: View {
    @Environment(\.modelContext) private var modelContext
    var username: String
    @Binding var ingredients: [String]
    @State private var inView = false
    @State private var showCookTimeSlider = false

    let allRecipes: [RecipeModel]
    let columns = [
        GridItem(.flexible()), // First column
        GridItem(.flexible())  // Second column
    ]
    
    // Computed property to filter recipes based on ingredients
    @State private var filteredRecipes: [RecipeModel] = []
    @State private var onlyIngredientsFiltered: [RecipeModel] = []
    let moreFilteringOptions = ["All", "Number of missing ingredients", "Vegetarian (coming soon)", "Gluten-Free (coming soon)"]
    @State private var maxCookTime: Float = 180 // 3 hours (in minutes)
    
    private func filterRecipes() {
        if ingredients.isEmpty {
            filteredRecipes = allRecipes
        } else {
            if !filteredRecipes.isEmpty {
                filteredRecipes.removeAll()
            }
            filteredRecipes = allRecipes.filter { recipe in
                ingredients.allSatisfy { ingredient in
                    recipe.keywords.contains { $0.lowercased().contains(ingredient.lowercased()) }
                }
            }
            onlyIngredientsFiltered = filteredRecipes
        }
    }
    private func fetchByCookTime() {
        let cookTime = Int(maxCookTime)
        
        filteredRecipes = onlyIngredientsFiltered
            .filter { recipe in
                recipe.total_time! <= cookTime
            }
            .sorted { $0.likes! > $1.likes! }
    }
    
    private func moreFiltering(filter: String) {
        if filter == "Number of missing ingredients" {
            filteredRecipes = filteredRecipes.sorted { recipeA, recipeB in
                let missingA = recipeA.ingredients.filter { !ingredients.contains($0) }.count
                let missingB = recipeB.ingredients.filter { !ingredients.contains($0) }.count
                return missingA < missingB
            }
        }
    }

    var body: some View {
        HStack {
            Menu ("More Options") {
                Button("All Results", action: { filterRecipes() }) // reset it to default
                Button("Number of missing ingredients", action: { moreFiltering(filter: "Number of missing ingredients") })
                Button("Cook Time") {
                    showCookTimeSlider = true
                }
                Button("Vegetarian (coming soon)", action: { moreFiltering(filter: "")})
                Button("Gluten-Free (coming soon)", action: { moreFiltering(filter: "")})
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        
        if showCookTimeSlider {
            VStack {
                Text("Maximum Cook time: \(Int(round(maxCookTime))) minutes")
                Slider(value: $maxCookTime, in: 0...180, step: 5)
                    .frame(width: 200)
                Text("Note: some recipes may require days of preparation")
                    .font(.caption)
            }
        }
        
        NavigationStack {
            ScrollView {
                if filteredRecipes.isEmpty {
                    Text("No matching recipes found. Try adjusting your ingredients.")
                        .foregroundColor(.gray)
                        .padding()
                } else {
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredRecipes, id: \.self) { recipe in
                            NavigationLink(destination: RecipeDetails(recipe: recipe, username: username)) {
                                RecipeCard(recipe: recipe)
                            }
                            .cornerRadius(5)
                            .shadow(radius: 6)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Select a Recipe")
        }
        .onAppear {
            filterRecipes()
        }
        .onChange(of: ingredients) { _, _ in
            filterRecipes()
        }
        .onChange(of: maxCookTime) { _, _ in
            fetchByCookTime()
        }

    }
} // End of view (RecipeView2)


struct RecipeDetails: View {
    let recipe: RecipeModel // Pass recipe as a regular property
    @State private var isLiked: Bool = false
    @Query var allProfiles: [ProfileModel]
    
    var username: String
    var profile: ProfileModel? {
        allProfiles.first { $0.username == username }
    }
    
    func toggleLike() async throws {
        guard let recipeName = recipe.recipe_name else {
            throw LikeError.invalidRecipeName
        }
        
        guard let username = profile?.username else {
            throw LikeError.userNotAuthenticated
        }
        
        let url = Constants.Urls.recipes.appendingPathComponent("\(recipeName)/likes")
        var request = URLRequest(url: url)
        
        let oldValue = isLiked // save in case "like" doesn't work (it should always work though)
        isLiked.toggle()
        
        request.httpMethod = isLiked ? "PUT" : "DELETE"  // Note: inverted logic
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        struct LikeRequest: Encodable {
            let username: String
        }
        request.httpBody = try JSONEncoder().encode(LikeRequest(username: username))
        
        
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw LikeError.invalidServerResponse
            }
            
            guard (200..<300).contains(httpResponse.statusCode) else {
                throw LikeError.serverError(statusCode: httpResponse.statusCode)
            }
        } catch {
            // Revert on failure
            isLiked = oldValue
            throw error
        }
    }

    enum LikeError: Error {
        case invalidRecipeName
        case userNotAuthenticated
        case invalidServerResponse
        case serverError(statusCode: Int)
    }
        
    var body: some View {
        ScrollView {
            VStack {
                VStack {
                    HStack {
                        VStack {
                            Text(recipe.recipe_name!)
                                .font(.title)
                                .bold()
                                .padding()
                            HStack {
                                Button {
                                    print("Button Tapped!")
                                    Task {
                                        do {
                                            try await toggleLike()
                                        } catch {
                                            // Handle error (show alert, revert UI, etc.)
                                            print("Like failed: \(error)")
                                        }
                                    }
                                } label: {
                                    Image(systemName: isLiked ? "heart.fill" : "heart")
                                        .font(.title)
                                        .foregroundColor(.red)
                                        .padding()
                                        .cornerRadius(8)
                                }
                                .contentShape(Rectangle())
                                
                                
                                Spacer()
                            }
                            

                        }
                        Spacer()
                        Text("Time to Make: \(recipe.total_time!) minutes")
                            .font(.subheadline)
                            .italic()
                    }
                    
                    AsyncImage(url: URL(string: recipe.image_url!))
                        .scaledToFill()
                        .frame(width: 300, height: 200)
                        .clipped()
                        .opacity(0.9)
                        .cornerRadius(15)
                }
                .padding()
                VStack {
                    // Display ingredients
                    Text("Ingredients")
                        .font(.title3)
                        .bold()
                    
                    if !recipe.ingredients.isEmpty {
                        LazyVStack(alignment: .leading) {
                            ForEach(recipe.ingredients, id: \.self) { ingredient in
                                Text("• \(ingredient)")
                                    .padding()
                            }
                        }
                    } else {
                        Text("No ingredients available.")
                    }
                }.padding()
                
                VStack {
                    Text("How To Make \(recipe.recipe_name!)")
                        .font(.title3)
                        .bold()
                    
                    if !recipe.instructions.isEmpty {
                        LazyVStack(alignment: .leading) {
                            ForEach(Array(zip(recipe.instruction_step, recipe.instructions)), id: \.1) { step, instruction in
                                Text("\(step): \(instruction)")
                                    .padding()

                            }
                        }
                    } else {
                        Text("No instructions available.")
                    }
                }
            }
        }
    }
}
