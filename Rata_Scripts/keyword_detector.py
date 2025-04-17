''' 
This file is used to detect keywords in the user-created recipe.
It will also scan for inapproriate content and reject the upload.
Otherwise, it will read through the ingredients list (provided by user)
It will use the spaCy library to detect the keywords in the ingredients list.
'''

import spacy
from spacy.matcher import PhraseMatcher
import csv
import json
import sys

def keyword_detector(ingredients, food_list, matcher):
    if ingredients is None or not ingredients:
        message = "Empty Ingredients list."
        return (False, message)
    # Check for banned words
    doc = nlp(ingredients.lower())
    matches = matcher(doc)
    matched_banned = [doc[start:end].text for _, start, end in matches if _ == 1]
    if matched_banned:
        message = f"Ingredients contain banned words: {', '.join(matched_banned)}"
        return (False, message)
    
    keywords = []
    # Check for food items
    matched_food = [doc[start:end].text for _, start, end in matches if _ == 0]
    if matched_food:
        keywords = [doc[start:end].text for _, start, end in matches if _ == 0]
        message = f"Ingredients contain food items: {', '.join(matched_food)}"
        return (True, message, keywords)
    
def instruction_detector(instructions, matcher):
    if instructions is None or not instructions:
        message = "Empty Instructions list."
        return (False, message)

    # Check for banned words
    doc = nlp(instructions.lower())
    matches = matcher(doc)
    matched_banned = [doc[start:end].text for _, start, end in matches if _ == 1]
    if matched_banned:
        message = f"Instructions contain banned words: {', '.join(matched_banned)}"
        return (False, message)
    else:
        message = "No banned words found."
        return (True, message)

if __name__ == "__main__":
    ingredient_dataset = "./ingredients.csv"
    banned_words_dataset = "./banned_words.csv"
    # user_ingredients = ---users will input this
    # user_instructions = ---users will input this
    # Command line argument python3 keyword_detector.py "ingredients" "instructions"
    if len(sys.argv) != 3:
        print("Usage: python3 keyword_detector.py <ingredients> <instructions>")
        sys.exit(1)
    user_ingredients = sys.argv[1]
    user_instructions = sys.argv[2]

    with open(ingredient_dataset) as f:
        reader = csv.reader(f)
        food_list = [row[0] for row in reader]
    # Convert food_list items into spaCy Doc patterns
    nlp = spacy.blank("en")
    matcher = PhraseMatcher(nlp.vocab)
    patterns = [nlp.make_doc(food.lower()) for food in food_list]
    matcher.add("FOOD", patterns) # Detects food paterns, default is 0

    # Load the banned words from a file or define them directly
    with open(banned_words_dataset, "r") as f:
        reader = csv.reader(f)
        banned_words = [row[0] for row in reader]

    # Convert banned words into spaCy Doc patterns
    banned_patterns = [nlp.make_doc(word.lower()) for word in banned_words]
    matcher.add("BANNED", banned_patterns) # Detects banned words, default is 1

    # Call Functions
    valid_ingredients, message, keywords = keyword_detector(user_ingredients, food_list, matcher)
    valid_instructions, message = instruction_detector(user_instructions, matcher)
    if not valid_ingredients:
        print(f"Invalid ingredients: {message}")
    if not valid_instructions:
        print(f"Invalid instructions: {message}")
    else:
        print("Ingredients and instructions are valid. Saving keywords to file.")

        with open("keywords.json", "w") as f:
            json.dump(keywords, f)


