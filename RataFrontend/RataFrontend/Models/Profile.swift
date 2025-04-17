//
//  UserStruct.swift
//  Rata
//
//  Created by Braden Hicks on 1/31/25.
//

import Foundation
import SwiftData


enum ProfileUploadError: Error {
    case usernameAlreadyExists
    case serverError(statusCode: Int)
    
    var errorDescription: String? {
            switch self {
                case .usernameAlreadyExists: return "Username already exists."
                case .serverError: return "Please check your internet connection."
            }
        }
}


@Model
final class ProfileModel {
    var username: String
    var liked_recipes: [Int] // recipe_id
    
    init(username: String, liked_recipes: [Int] = []) {
        self.username = username
        self.liked_recipes = liked_recipes
    }
}

struct Profile: Decodable, Encodable {
    let username: String
    let password: String?
    let liked_recipes: [Int] // save the recipe_id
    let email: String
}




struct ProfileLoader {
    
    func findProfile(username: String) async throws -> (Profile, HTTPURLResponse)? {
        let defaults = UserDefaults.standard
        let etag = defaults.string(forKey: "etag")
        var headers: [String:String] = ["Content-Type": "applications.json"]
        if let etag {
            headers["If-None-Match"] = etag
        }
        let url = Constants.Urls.profiles.appendingPathComponent(username)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.allHTTPHeaderFields = headers
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        do {
            let profile = try JSONDecoder().decode(Profile.self, from: data)
            return (profile, httpResponse)
        } catch {
            print("Unexpected error: \(error.localizedDescription)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print(jsonString) // This should print the actual JSON content
                print(String(reflecting: Profile.self))
            } else {
                print("Failed to convert data to a string")
            }
            return nil
        }
        
        // should never reach here
        return nil
    }
    
    func uploadProfile(profile: Profile) async throws -> HTTPURLResponse? {
//        print("username: \(profile.username) - password: \(profile.password) ")
        let defaults = UserDefaults.standard
        let etag = defaults.string(forKey: "etag")
        
        var headers: [String:String] = ["Content-Type": "application/json"]
        
        if let etag {
            headers["If-None-Match"] = etag
        }
        
        // Upload to profiles table
        var request = URLRequest(url: Constants.Urls.profiles)
        request.httpMethod = "POST"
        
        for (key, value) in headers {
            request.addValue(value, forHTTPHeaderField: key)
        }
        let jsonData = try JSONEncoder().encode(profile)
        request.httpBody = jsonData // add data to the request, will try to send to the server side
        
        let session = URLSession.shared
        let (_, response) = try await session.data(for: request) // network request
        
        guard let httpResponse = response as? HTTPURLResponse else {
           throw NSError(domain: "Invalid Response", code: -1, userInfo: nil)
        }
        
        guard httpResponse.statusCode >= 200 && httpResponse.statusCode < 300 else { // status code in 200 - 300 range => successful upload (201 means created)
            throw ProfileUploadError.serverError(statusCode: httpResponse.statusCode)
        }
        
        return httpResponse
    }
}
