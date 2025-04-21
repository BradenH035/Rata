//
//  EnterUsernameView.swift
//  Rata
//
//  Created by Braden Hicks on 3/8/25.
//

import Foundation
import SwiftUI
import SwiftData


struct EnterUsernameView: View {
    @Environment(\.modelContext) private var modelContext
    @State var username: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isNavigating: Bool = false
    @State private var isLoading: Bool = false
    @State private var createAccount: Bool = false
    let recipeLoader = RecipeLoader()
    let profileLoader = ProfileLoader()

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if isLoading {
                        ProgressView("Importing your recipes...")
                            .padding()
                        
                    } else {
                        Text("Login")
                        Form {
                            HStack {
                                Text("Username:")
                                TextField(text: $username, prompt: Text("")){
                                    Text("Username")
                                }
                            }
                            HStack {
                                Text("Password:")
                                SecureField(text: $password, prompt: Text("")) {
                                    Text("Password")
                                }
                            }
                        } // End of Form
                        
                        HStack {
                            Button("Sign In") {
                                Task {
                                    do {
                                        try await signIn(username: username, password: password)
                                        
                                        isNavigating = true
                                    } catch {
                                        print("There was an error signing in")
                                    }
                                }
                            }
                            .padding()
                            Button("Create Account") {
                                createAccount = true
                            }
                        } // End of HStack
                    } // End of VStack
                }
                // Navigation happens only when isNavigating is set to true
                NavigationLink("", destination: ContentView(username: username), isActive: $isNavigating)
                    .hidden() // Hide the NavigationLink UI
                
                // Navigate to CreateAccountView when button is clicked
                NavigationLink("", destination: CreateAccountView(), isActive: $createAccount)
                    .hidden()
    
                
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
            }
        }
    } // end of body



    private func startImport(user: Profile) async throws -> Bool {
        errorMessage = nil
        do {
            // Initialize DataImporter with the ModelContext and RecipeLoader
            let dataImporter = DataImporter(profile: user, context: modelContext, recipeLoader: recipeLoader, profileLoader: profileLoader)
            let doneLoading = try await dataImporter.importData(username: username) // should be true
            return doneLoading
        } catch {
            errorMessage = error.localizedDescription
            print("Error Message \(String(describing: errorMessage))")
        }
        return false
    }
    private func signIn(username: String, password: String) async throws {
        guard !username.isEmpty && !password.isEmpty else {
            throw NSError(domain: "SignInError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Username and password are required."])
        }
        guard password.count <= 12 else {
            throw NSError(domain: "SignInError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Password must be less than 12 characters."])
        }
        
        
        // Find existing profile
        guard let (user, _) = try await profileLoader.findProfile(username: username) else {
            throw NSError(domain: "SignInError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid login information\n\nNew User? Close this message and create an account below! \n\nForgot your password? Click this link to reset it."])
        }
        
        do {
            isLoading = true
            try await isNavigating = startImport(user: user)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            print("Error Message \(String(describing: errorMessage))")
        }
    }
}

