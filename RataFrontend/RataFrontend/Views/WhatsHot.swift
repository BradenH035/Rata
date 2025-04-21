//
//  WhatsHot.swift
//  Rata
//
//  Created by Braden Hicks on 2/22/25.
//
import Foundation
import SwiftUI
import SwiftData

struct WhatsHotView: View {
    @Environment(\.modelContext) private var modelContext
    // @Query(sort: \RecipeModel.likes, order: .reverse) var sortedModels: [RecipeModel]
    static var fetchDescriptor: FetchDescriptor<RecipeModel> {
        var descriptor = FetchDescriptor<RecipeModel>(
            predicate: nil,
            sortBy: [SortDescriptor(\.likes, order: .reverse)]
        )
        descriptor.fetchLimit = 20
        return descriptor
    }
    @Query(WhatsHotView.fetchDescriptor) private var sortedModels: [RecipeModel]
    var username: String
    var body: some View {
        NavigationStack {
            ScrollView {
                ForEach(sortedModels) { recipe in
                    NavigationLink(destination: RecipeDetails(recipe: recipe, username: username)) {
                        ZStack {
                            AsyncImage(url: URL(string: recipe.image_url!))
                                .scaledToFill()
                                .frame(width: 300, height: 200)
                                .clipped()
                                .opacity(0.9)
                                .cornerRadius(15)

                            ZStack {
                                    Image(systemName: "flame.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 50))
                                    
                                    
                                    Text("\(recipe.likes!)")
                                        .foregroundColor(.white)
                                        .font(.system(size: 24, weight: .bold))
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                                .padding(.leading, 10)
                                .padding(.top, 10)
                                .offset(x: 15)
                            
                            Text(recipe.recipe_name!)
                                .font(.system(size: 35, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                .padding(.trailing, 20)
                                .padding(.bottom, 10)
                            

                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Popular Recipes")
                            .font(.title)
                        Text("Here's what others have been making!")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

