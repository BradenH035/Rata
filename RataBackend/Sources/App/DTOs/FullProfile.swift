//
//  FullProfile.swift
//  RataBackend
//
//  Created by Braden Hicks on 3/8/25.
//
import Fluent
import Vapor


struct FullProfile: Content {
	let username: String
	let password: String
	let liked_recipes: [Int]
    let email: String
}

