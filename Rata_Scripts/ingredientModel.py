import csv
import spacy
from spacy.matcher import PhraseMatcher
import json

recipe_dataset = "./recipes.json"
ingredient_dataset= "./ingredients.csv"
def extract_food_terms(ingredients, food_list, recipe):
    """
    Extracts and labels food-related terms from a sentence using spaCy's PhraseMatcher.

    Args:
        sentence (str): Sentence to process.
        food_list (list of str): List of known food items/phrases to match.

    Returns:
        dict: 
            - "sentence": Original sentence.
            - "matches": List of matched food terms (as strings).
            - "labeled_tokens": List of (token, label) tuples for each token in the sentence.
    """
    nlp = spacy.blank("en")
    matcher = PhraseMatcher(nlp.vocab)

    # Convert food_list items into spaCy Doc patterns
    patterns = [nlp.make_doc(food.lower()) for food in food_list]
    matcher.add("FOOD", patterns)

    results = []
    for sentence in ingredients:
        doc = nlp(sentence.lower())  # Convert to lowercase for case-insensitive matching
        matches = matcher(doc)

        matched_foods = [doc[start:end].text for _, start, end in matches]

        labeled_tokens = []
        for token in doc:
            label = "FOOD" if any(token.i in range(start, end) for _, start, end in matches) else "O"
            labeled_tokens.append((token.text, label))
        #print(recipe, sentence, matched_foods, labeled_tokens)
        results.append({
            "recipe": recipe,
            "sentence": sentence,
            "matches": matched_foods,
            "labeled_tokens": labeled_tokens,
        })

    return results

def label_ingredients(data, ingredient_dataset, labeled_data):
    for recipe in data:
        labeled = extract_food_terms(recipe["ingredients"], ingredient_dataset, recipe["recipe_name"])
        labeled_data.append(labeled)
    return labeled_data

if __name__ == "__main__":
    labeled_data = []
    with open(ingredient_dataset) as f:
        reader = csv.reader(f)
        food_list = [row[0] for row in reader]
    with open(recipe_dataset) as f:
        data = json.load(f)
    labeled_data = label_ingredients(data, food_list, labeled_data)
    #print(labeled_data)
    with open("labeled_data.json", "w") as f:
        json.dump(labeled_data, f, indent=4)
