//
//  FavoritesView.swift
//  Rata
//
//  Created by Braden Hicks on 3/4/25.
//
import Foundation
import SwiftData
import SwiftUI

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    let columns = [
        GridItem(.flexible()), GridItem(.flexible())
    ]
    var username: String
    var likedRecipes: [RecipeModel]
    
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                        VStack {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                                .scaleEffect(1.5)
                            Text("Loading your favorites...")
                                .font(.footnote)
                                .foregroundColor(.gray)
                        }
                } else if likedRecipes.isEmpty {
                    VStack {
                        Text("You haven't saved any recipes yet.")
                            .font(.title2)
                        Text("Tip: You can save recipes you like by clicking the heart icon")
                            .font(.footnote)
                    }
                } else {
                Text("Here are your favorites!")
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 20) {
                            ForEach(likedRecipes, id: \.self) { recipe in
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
            }
            .navigationTitle("Your Favorites")
        }
        .task {
            isLoading = true
            let timeout: UInt64 = 30_000_000_000
            let checkInterval: UInt64 = 300_000_000
            var waited: UInt64 = 0

            while waited < timeout {
                if !likedRecipes.isEmpty {
                    break
                }


                try? await Task.sleep(nanoseconds: checkInterval)
                waited += checkInterval
            }
            isLoading = false
        }
    }
}
