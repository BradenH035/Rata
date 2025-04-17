import json

data = './fullIngredientList.json'
with open(data) as f:
    recipes = json.load(f)

# Turn all the ingredients from data json into a list, remove duplicates
ingredients = []


for recipe in recipes:    
    ingredients_to_add = recipe['ingredients']
    for ingredient in ingredients_to_add:
        if ingredient not in ingredients:
            ingredients.append(ingredient)

# save ingredients to a csv file
with open('ingredients.csv', 'w') as f:
    for ingredient in ingredients:
        f.write(f"{ingredient}\n")
        

    