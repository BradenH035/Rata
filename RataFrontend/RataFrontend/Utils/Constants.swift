//
//  Constants.swift
//  Rata
//
//  Created by Braden Hicks on 2/1/25.
//

import Foundation
struct Constants {
    private static let baseURLPath = "http://127.0.0.1:8080" // temp for development
    
    struct Urls {
        static let recipes = URL(string: "\(baseURLPath)/recipes")!
        static let profiles = URL(string: "\(baseURLPath)/profiles")!
    }
}
