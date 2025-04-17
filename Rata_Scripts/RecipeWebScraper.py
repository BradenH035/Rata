from urllib.robotparser import RobotFileParser
import requests
from bs4 import BeautifulSoup
from fractions import Fraction
import re
import json

def replace_with_decimal(time_string):
    # Regex pattern to identify whole numbers and fractions
    pattern = re.compile(r"(\d+)?\s*([¼½¾⅓⅔⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞]?)\s*(hour[s]?|minute[s]?)", re.IGNORECASE)

    # Fractional mapping for Unicode characters
    fraction_mapping = {
        "¼": 1/4,
        "½": 1/2,
        "¾": 3/4,
        "⅓": 1/3,
        "⅔": 2/3,
        "⅕": 1/5,
        "⅖": 2/5,
        "⅗": 3/5,
        "⅘": 4/5,
        "⅙": 1/6,
        "⅚": 5/6,
        "⅛": 1/8,
        "⅜": 3/8,
        "⅝": 5/8,
        "⅞": 7/8,
    }

    # Process matches
    matches = pattern.search(time_string)
    whole = int(matches.group(1)) if matches.group(1) else 0
    fraction = matches.group(2) if matches.group(2) else 0
    unit = matches.group(3)
    if fraction in fraction_mapping:
        fraction = fraction_mapping[fraction]
    else:
        fraction = 0
    # return value
    value = whole + fraction
    return str(value) + " " + unit
            

# Helper function to find basic phrases
def find_time_helper(phrase):    
     # Pattern 1: detect 'hours' and 'minutes' and add them together
    pattern1 = re.compile(r"(\d+(?:\.\d+)?)\s*hour[s]?\s*(\d+(?:\.\d+)?)\s*minute[s]?", re.IGNORECASE)
    # Pattern 2: detect 'hours' and convert to minutes
    pattern2 = re.compile(r"(\d+(?:\.\d+)?)\s*hour[s]?", re.IGNORECASE)
    # Pattern 3: only 'minutes'
    pattern3 = re.compile(r"(\d+(?:\.\d+)?)\s*minute[s]?")
    # Pattern 4: 'day'
    pattern4 = re.compile(r"(\d+(?:\.\d+)?)\s*day[s]?")
    # Pattern 5: 'overnight'
    pattern5 = re.compile(r"\bovernight[s]?\b", re.IGNORECASE)
    # Pattern 6: fractions like 1/4, 1/2, 3/4
    pattern6 = re.compile(r"(\d+)?\s*([¼½¾⅓⅔⅕⅖⅗⅘⅙⅚⅛⅜⅝⅞])\s*(hour[s]?|minute[s]?)", re.IGNORECASE)

    hours = 0
    minutes = 0
    
    if pattern6.search(phrase):
        match = pattern6.search(phrase)
        phrase = replace_with_decimal(phrase)
    
        
    if pattern5.search(phrase):
        match = pattern5.search(phrase)
        minutes += 8 * 60
    if pattern4.search(phrase):
        match = pattern4.search(phrase)
        hours = 0
        minutes += int(match.group(1)) * 24 * 60 if match.group(1) else 0

    if pattern1.search(phrase):
        match = pattern1.search(phrase)
        hours = float(match.group(1)) if match.group(1) else 0
        minutes = float(match.group(2)) if match.group(2) else 0
            
    if pattern2.search(phrase) and not pattern1.search(phrase):
        match = pattern2.search(phrase)
        hours = float(match.group(1)) if match.group(1) else 0
        minutes = 0

    if pattern3.search(phrase) and not pattern1.search(phrase) and not pattern2.search(phrase):
        match = pattern3.search(phrase)
        hours = 0
        minutes = float(match.group(1)) if match.group(1) else 0

    return hours, minutes


def find_time(phrase):
    # Patterns to detect keywords and their relationships
    pattern_plus = re.compile(r"(.*?)(plus)(.*)", re.IGNORECASE)
    pattern_or = re.compile(r"(.*?)(or)(.*)", re.IGNORECASE)
    pattern_and = re.compile(r"(.*?)(and)(.*)", re.IGNORECASE)

    # Base case: If the phrase contains no keywords, process directly
    if not any(keyword in phrase.lower() for keyword in ["plus", "or", "and"]):
        return find_time_helper(phrase)  # Helper function processes individual segments
    
     # Handle 'or': Choose the larger time from two segments
    if pattern_or.search(phrase):
        match = pattern_or.search(phrase)
        phrase1, phrase2 = match.group(1), match.group(3)
        h1, m1 = find_time(phrase1.strip())  # Recursive call
        h2, m2 = find_time(phrase2.strip())  # Recursive call
        time1 = h1 * 60 + m1
        time2 = h2 * 60 + m2
        larger_time = max(time1, time2)
        return larger_time // 60, larger_time % 60

    # Handle 'plus': Add the times from two segments
    if pattern_plus.search(phrase):
        match = pattern_plus.search(phrase)
        phrase1, phrase2 = match.group(1), match.group(3)
        h1, m1 = find_time(phrase1.strip())  # Recursive call
        h2, m2 = find_time(phrase2.strip())  # Recursive call
        total_hours = h1 + h2
        total_minutes = m1 + m2
        return total_hours + total_minutes // 60, total_minutes % 60

    # Handle 'and': Add the times from two segments
    if pattern_and.search(phrase):
        match = pattern_and.search(phrase)
        phrase1, phrase2 = match.group(1), match.group(3)
        h1, m1 = find_time(phrase1.strip())  # Recursive call
        h2, m2 = find_time(phrase2.strip())  # Recursive call
        total_hours = h1 + h2
        total_minutes = m1 + m2
        return total_hours + total_minutes // 60, total_minutes % 60

    # Default case if no matches
    return 0, 0

# NYT Web Scraper
def scrape_nyt_recipes():
    rp = RobotFileParser()
    rp.set_url("https://cooking.nytimes.com/topics/dinner-recipes/robots.txt")
    rp.read()

    user_agent = "YourScraperBot"
    url_to_check = "https://cooking.nytimes.com/recipes/1025601-grain-bowl-with-sardines-and-sauce-moyo"

    if rp.can_fetch(user_agent, url_to_check):
        print("You are allowed to scrape this page!")
    else:
        print("Scraping this page is disallowed by robots.txt")

    url = "https://cooking.nytimes.com/?source=youtube&hs_id=26992517&ds_c=&ds_c=71700000052595478&site=google&network=g&campaign_id=1400169272&ad-keywords=auddevgate&gad_source=1&gclid=CjwKCAiA65m7BhAwEiwAAgu4JOBLpGMKJHGtAVBW9OllbnaT2FCUxt2HIXOXfhhEYd2Zg8vQXral5RoCmYMQAvD_BwE&gclsrc=aw.ds"
    response = requests.get(url)
    soup = BeautifulSoup(response.text, 'html.parser')

    # Step 2: Find all the "By Meal" links
    by_meal_section = soup.find('ul', attrs={'aria-labelledby': 'desktopNav-recipes-by-meal'})

    subpages = []

    if by_meal_section:
        links = by_meal_section.find_all('a')  # Find all <a> tags
        for link in links:
            meal_name = link.text.strip()  # Get the text of the link
            meal_url = link['href']  # Get the URL of the link
            subpages.append((meal_name, meal_url))

    else:
        print("The 'By Meal' section was not found.")
        
    recipes = {}
    # Step 3: Scrape the subpages
    for meal_name, meal_url in subpages:
        response = requests.get(meal_url)
        soup = BeautifulSoup(response.text, 'html.parser')

        # Find all the recipe links
        recipe_cards = soup.find_all("section", class_="supercollectionpackage_carouselWrapper__Hk_5i")  # Locate all <ul> with the specific class
        #print(f"Found {len(recipe_cards)} recipe cards on the {meal_name} page.")

        # Step 3: Iterate through each recipe card and extract information
        for section in recipe_cards:
            # Find all <a> tags within the section that contain recipe details
            recipe_links = section.find_all('a', class_='link_link__7WCQy link_default__lKxiG')
            
            # Extract and print details for each recipe
            for recipe in recipe_links:
                href = recipe.get('href') if recipe else None
                img_tag = recipe.find('img') if recipe else None
                recipe_name = img_tag.get('alt') if img_tag else None
                image_url = img_tag.get('src') if img_tag else None              
                if recipe_name not in recipes:
                    recipes[recipe_name] = {
                        "link": href,
                        "image_url": image_url
                        }

    for recipe_name, recipe_data in recipes.items():
        recipe_url = recipe_data.get("link")
        response = requests.get(recipe_url)
        soup = BeautifulSoup(response.text, 'html.parser')

        total_time_label = soup.find('dt', string='Total Time')
        if total_time_label:
            total_time_value = total_time_label.find_next_sibling('dd').text
            total_time_h_m = find_time(total_time_value)
            total_time = total_time_h_m[0] * 60 + total_time_h_m[1]
            #print(total_time_value)
            #print(total_time_h_m)
            #print(total_time)
            recipes[recipe_name]["total_time_text"] = total_time_value
            recipes[recipe_name]["total_time"] = total_time
        
        # Extract the number from the Total Prep Time (e.g., "20 minutes" -> 20)
        prep_time_label = soup.find('dt', string='Prep Time')
        if prep_time_label:
            prep_time_value = prep_time_label.find_next_sibling('dd').text
            prep_time_h_m = find_time(prep_time_value)
            prep_time = prep_time_h_m[0] * 60 + prep_time_h_m[1]
            recipes[recipe_name]["prep_time_text"] = prep_time_value
            recipes[recipe_name]["prep_time"] = prep_time

        # Extract the number from the Total Cook Time (e.g., "20 minutes" -> 20)
        cook_time_label = soup.find('dt', string='Total Time')
        if cook_time_label:
            cook_time_value = cook_time_label.find_next_sibling('dd').text
            cook_time_h_m = find_time(cook_time_value)
            cook_time = cook_time_h_m[0] * 60 + cook_time_h_m[1]
            recipes[recipe_name]["cook_time_text"] = cook_time_value 
            recipes[recipe_name]["cook_time"] = cook_time

        servings_label = soup.find('dt', string='Yield')
        if servings_label:
            servings_value = servings_label.find_next_sibling('dd').text
            recipes[recipe_name]["servings"] = servings_value

        elements = soup.find_all('li', class_='pantry--ui ingredient_ingredient__rfjvs')
        # Iterate through the elements and extract their text content
        descriptions = [re.sub(r"(\d+)\s*(\(.*?\)|[a-zA-Z]+.*)", r"\1 \2", element.text) for element in elements]
    
        recipes[recipe_name]["ingredients"] = descriptions

        # Extract the preparation instructions
        steps = soup.find_all('li', class_='preparation_step__nzZHP')
        instructions = [re.sub(r"^Step \d+", "", step.text).strip() for step in steps]
        recipes[recipe_name]["instructions"] = instructions
        
    # remove empty recipes
    recipes = {k: v for k, v in recipes.items() if v.get("ingredients")}
    
    return recipes


def write_recipe_file(recipes):
    add_me = []
    for recipe_name, recipe_data in recipes.items():
        input = {
            "recipe_name": recipe_name,
            "ingredients": recipe_data["ingredients"]
        }
        add_me.append(input)

    with open("recipes.json", "w") as file:
        json.dump(add_me, file)

def load_ingredients_only(recipes):
    ingredient_list = []
    with open("labeled_data.json", "r") as file:
        ingredient_list = json.load(file)
   
    for recipe in recipes:
        recipe_matches = {}
        for single_recipe in ingredient_list:
            for item in single_recipe:
                recipe_name = item['recipe']  # Access the 'recipe' from the first dictionary
                if recipe_name == recipe:
                    if recipe_name not in recipe_matches:
                        recipe_matches[recipe_name] = []
                    recipe_matches[recipe_name].extend(item.get('matches', []))
        print(recipes[recipe])
        recipes[recipe]["ingredient_keywords"] = recipe_matches[recipe]

    

if __name__ == "__main__":
    recipes = scrape_nyt_recipes()
    # save recipe ingredients to a file
    write_recipe_file(recipes)
    # load ingredients only, add to recipes dictionary
    load_ingredients_only(recipes)
    print(recipes["Ginger-Scallion Steamed Fish"])
    #save to file
    with open("recipes_final.json", "w") as file:
        json.dump(recipes, file)