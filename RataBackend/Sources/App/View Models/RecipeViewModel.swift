//
//  ViewModel.swift
//  RataBackend
//
//  Created by Braden Hicks on 1/31/25.
//

import Foundation
import Combine

class RecipeViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []
    @Published var errorMessage: String? = nil

    private var cancellables = Set<AnyCancellable>()

    func fetchRecipes() {
        guard let url = URL(string: "http://localhost:8080/recipes") else {
            errorMessage = "Invalid URL"
            return
        }

        URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: [Recipe].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                case .finished:
                    break
                }
            } receiveValue: { recipes in
                self.recipes = recipes
            }
            .store(in: &cancellables)
    }
}
