//
//  RataFrontendApp.swift
//  RataFrontend
//
//  Created by Braden Hicks on 4/15/25.
//

import SwiftUI

@main
struct RataApp: App {
    var body: some Scene {
        WindowGroup {
            EnterUsernameView()
        }
        .modelContainer(for: [RecipeModel.self, ProfileModel.self])
    }
}
