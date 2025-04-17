//
//  ContentView.swift
//  Rata
//
//  Created by Braden Hicks on 1/21/25.
//
import Foundation
import SwiftUI
import SwiftData


struct ContentView: View {
    let username: String
    @Environment(\.modelContext) private var modelContext // Access the ModelContext
    @State private var errorMessage: String?
    let recipeLoader = RecipeLoader()
    @Query var recipeModels: [RecipeModel]
    //let recipeModels: [RecipeModel]
    @Query var allProfiles: [ProfileModel]
    
    // Computed property to find our profile
    var profile: ProfileModel? {
        allProfiles.first { $0.username == username }
    }

    var likedRecipes: [RecipeModel] {
        guard let profile = profile else { return [] }
        return recipeModels.filter { recipe in
            if let id = recipe.recipe_id {
                return profile.liked_recipes.contains(id)
            }
            return false
        }
    }
    
    var body: some View {
        let lightGreen = Color(red: 0.11, green: 0.8, blue: 0.6)
        let tigerlily = Color(red: 0.859, green: 0.529, blue: 0.502)
        NavigationStack {
            GeometryReader { geometry in
                VStack(spacing: geometry.size.height * 0.03) {
                    NavigationLink(destination: RecipeFiltering(username: username)) {
                        ZStack {
                            Image("findRecipeButton")
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width * 0.9, height: geometry.size.height*0.25)
                                .clipped()
                                .opacity(0.9)
                            
                            Text("Find a Recipe")
                                .font(.system(size: 50, weight: .bold, design: .default))
                                .foregroundColor(.white)
                        }
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height*0.25)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(lightGreen, lineWidth: 2.5)
                        )
                    }
                    
                    // What's Hot Button
                    NavigationLink(destination: WhatsHotView(username: username)) {
                        ZStack {
                            Image("flambe-desserts")
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width * 0.9, height: geometry.size.height*0.25)
                                .clipped()
                                .opacity(0.9)
                            
                            Text("What's Hot")
                                .font(.system(size: 50, weight: .bold, design: .default))
                                .foregroundColor(.white)
                        }
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height*0.25)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.black, lineWidth: 2.5)
                        )
                    }
                    
                    // Your Favorites Button
                    NavigationLink(destination: FavoritesView(username: username, likedRecipes: likedRecipes)) {
                        ZStack {
                            Image("sharing-food")
                                .resizable()
                                .scaledToFill()
                                .frame(width: geometry.size.width * 0.9, height: geometry.size.height*0.25)
                                .clipped()
                                .opacity(0.9)
                            
                            Text("Your Favorites")
                                .font(.system(size: 50, weight: .bold, design: .default))
                                .foregroundColor(.white)
                        }
                        .frame(width: geometry.size.width * 0.9, height: geometry.size.height*0.25)
                        .cornerRadius(15)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(tigerlily, lineWidth: 2.5)
                        )
                    }
                    .padding(geometry.size.height * 0.001)
                    
                    
                    
                    HStack {
                        NavigationLink(destination: AddRecipeView()) {
                            VStack {
                                Image(systemName: "plus")
                                    .font(.system(size: geometry.size.height*0.08))
                                Text("Add Recipe")
                                    .font(.system(size:geometry.size.height*0.035))
                            }
                        }
                        .padding()
                        .foregroundColor(.black)
                        
                        NavigationLink(destination: GroceryListView()) {
                            VStack {
                                Image(systemName: "list.bullet.clipboard")
                                    .font(.system(size: geometry.size.height*0.06))
                                Text("Grocery List")
                                    .font(.system(size:geometry.size.height*0.035))
                            }
                        }
                        .padding()
                        .foregroundColor(.black)
                    }
                    
                }
                .frame(width: geometry.size.width)
                .navigationTitle("RATA")
            }
        }
        
    } // End of Body
} // End of ContentView



struct AddRecipeView: View {
    var body: some View {
        Text("Add a Recipe Screen")
            .font(.largeTitle)
            .bold()
            .navigationTitle("Add Recipe")
    }
}

struct GroceryListView: View {
    var body: some View {
        Text("Grocery List Screen")
            .font(.largeTitle)
            .bold()
            .navigationTitle("Your Grocery List")
    }
}

