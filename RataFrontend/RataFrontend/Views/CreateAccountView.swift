//
//  CreateAccountView.swift
//  Rata
//
//  Created by Braden Hicks on 4/1/25.
//

import Foundation
import SwiftUI
import SwiftData


struct CreateAccountView: View {
    @Environment(\.modelContext) private var modelContext
    @State var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmedPassword: String = ""
    @State private var errorMessage: String?
    @State private var acountIsCreated: Bool = false
    let recipeLoader = RecipeLoader()
    let profileLoader = ProfileLoader()

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Text("Create an account")
                    Form {
                        HStack {
                            Text("Username:")
                            TextField(text: $username, prompt: Text("Required")){
                                Text("Username")
                            }
                        }
                        
                        HStack {
                            Text("Email:")
                            TextField(text: $email, prompt: Text("Required")) {
                                Text("Email")
                            }
                        }
                        HStack {
                            VStack {
                                Text("Password:")
                                Text("(max. 12 characters)")
                                    .font(.system(size:12))
                            }
                            SecureField(text: $password, prompt: Text("Required")) {
                                Text("Password")
                            }
                        }
                        
                        HStack {
                            Text("Confirm Password:")
                            SecureField(text: $confirmedPassword, prompt: Text("Required")) {
                                Text("Confirm Password")
                            }
                        }
                    }
                    
                    Button("Create Account") {
                        Task {
                            do {
                                try await signIn(username: username, password: password, confirmedPassword: confirmedPassword, email: email)
                                acountIsCreated = true // Only navigate after sign-in is successful
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                        }
                    }
                    .padding()
                }
                    
                NavigationLink("", destination: ContentView(username: username), isActive: $acountIsCreated)
                    .hidden() // Hide the NavigationLink UI
                
                if errorMessage != nil {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 20) {
                        Text(errorMessage!)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding()
                        
                        Button("Close") {
                            errorMessage = nil
                        }
                        .padding()
                        .background(Color.white)
                        .foregroundColor(.black)
                        .cornerRadius(8)
                    }
                    .frame(width: 300)
                    .padding()
                    .background(Color(red: 0.49, green: 0.5, blue: 0.58, opacity: 0.3))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.black, lineWidth: 1)
                    )
                    .shadow(radius: 10)
                }
            } // End of ZStack
        }
    } // end of body
        
        
        
    private func startImport(user: Profile) {
        errorMessage = nil
        Task {
            do {
                // Initialize DataImporter with the ModelContext and RecipeLoader
                let dataImporter = DataImporter(profile: user, context: modelContext, recipeLoader: recipeLoader, profileLoader: profileLoader)
                try await dataImporter.importData(username: username)
            } catch {
                errorMessage = error.localizedDescription
                print("Error Message \(String(describing: errorMessage))")
            }
        }
    }
    
    private func signIn(username: String, password: String, confirmedPassword: String, email: String) async throws {
        guard !username.isEmpty && !password.isEmpty && !confirmedPassword.isEmpty && !email.isEmpty else {
            throw NSError(domain: "SignInError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Username, password, and email are required."])
        }
        guard password.count <= 12 else {
            throw NSError(domain: "SignInError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Password must be less than 12 characters."])
        }
        
        guard password == confirmedPassword else {
            throw NSError(domain: "SignInError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Passwords must match."])
        }
        
        let newUser = Profile(username: username, password: password, liked_recipes: [], email: email)
        try await profileLoader.uploadProfile(profile: newUser)
        print("New user created with username: \(newUser), password: \(newUser.password)")
        startImport(user: newUser)
    }
}

