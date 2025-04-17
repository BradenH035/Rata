import json
import psycopg2
import os

db_config = {
    'dbname': os.getenv('DB_NAME'), # rata
    'user': os.getenv('DB_USER'), # bradenhicks
    'password': os.getenv('DB_PASSWORD'), # Basket2Ball
    'host': os.getenv('DB_HOST', 'localhost'),
    'port': int(os.getenv('DB_PORT', 5432))
}

print(db_config)
def upload_nested_json(json_file):
    try:
        # Connect to PostgreSQL
        conn = psycopg2.connect(**db_config)
        cursor = conn.cursor()
        # Load JSON data
        with open(json_file, 'r', encoding='utf-8') as file:
            data = json.load(file)
        
        # Insert data into recipes and instructions
        for entry, recipe in data.items():
            # Set default values for missing keys
            recipe['total_time'] = recipe.get('total_time', 0)
            recipe['total_time_text'] = recipe.get('total_time_text', '0 minutes')
            recipe['cook_time'] = recipe.get('cook_time', 0)
            recipe['cook_time_text'] = recipe.get('cook_time_text', '0 minutes')
            recipe['prep_time'] = recipe.get('prep_time', 0)
            recipe['prep_time_text'] = recipe.get('prep_time_text', '0 minutes')

            print(recipe["total_time"])
            print(recipe["total_time_text"])

            cursor.execute(
                "INSERT INTO recipes (link, image_url, total_time, total_time_text, cook_time, cook_time_text, prep_time, prep_time_text, recipe_name) "
                "VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s) RETURNING recipe_id",
                (
                    recipe.get('link', ''),
                    recipe.get('image_url', ''),
                    recipe['total_time'],
                    recipe["total_time_text"],
                    recipe['cook_time'],
                    recipe["cook_time_text"],
                    recipe['prep_time'],
                    recipe["prep_time_text"],
                    entry
                )
            )
            recipe_id = cursor.fetchone()[0]

            # Insert steps into instructions table
            for step_number, instruction in enumerate(recipe.get('instructions', []), start=1):
                print(f"Step {step_number}: {instruction}")
                cursor.execute(
                    "INSERT INTO instructions (recipe_id, step_number, instruction) VALUES (%s, %s, %s) RETURNING instruction_id",
                    (recipe_id, step_number, instruction)
                )


            # Insert ingredients into ingredients table
            for ingredient in recipe.get('ingredients', []):
                cursor.execute(
                    "INSERT INTO ingredients (recipe_id, ingredient) VALUES (%s, %s) RETURNING ingredient_id",
                    (recipe_id, ingredient)
                )
            
            # Insert keywords into keywords table
            for keyword in recipe.get('ingredient_keywords', []):
                cursor.execute(
                    "INSERT INTO keywords (recipe_id, keyword) VALUES (%s, %s) RETURNING keyword_id",
                    (recipe_id, keyword)
                )
                
        conn.commit()
        print("Successfully uploaded nested JSON data.")
        
    except Exception as e:
        print(f"An error occurred: {e}")
    finally:
        cursor.close()
        conn.close()

upload_nested_json('final_recipes_cleaned.json')
