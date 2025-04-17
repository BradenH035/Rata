import json

def clean_json_unicode(input_file, output_file):
    """
    Reads a JSON file, decodes Unicode escape sequences, and writes the cleaned data back to a new JSON file.

    :param input_file: Path to the input JSON file.
    :param output_file: Path to save the cleaned JSON file.
    """
    try:
        # Read the JSON file
        with open(input_file, 'r', encoding='utf-8') as file:
            data = json.load(file)

        # Recursively clean Unicode escape sequences
        def decode_unicode(obj):
            if isinstance(obj, str):
                # Decode common Unicode sequences
                replacements = {
                    "\u00bd": "½",
                    "\u2153": "⅓",
                    "\u00bc": "¼",
                    "\u00e1": "á",
                    "\u00e9": "é",
                    "\u00ed": "í",
                    "\u00f3": "ó",
                    "\u00fa": "ú",
                    "\u2013": "–",
                    "\u2014": "—",
                    "\u2018": "‘",
                    "\u2019": "’",
                    "\u201c": "“",
                    "\u201d": "”",
                    "\u2154": "⅔",

                }
                for unicode_seq, replacement in replacements.items():
                    obj = obj.replace(unicode_seq, replacement)
                return obj
            elif isinstance(obj, list):
                return [decode_unicode(item) for item in obj]
            elif isinstance(obj, dict):
                return {key: decode_unicode(value) for key, value in obj.items()}
            return obj

        cleaned_data = decode_unicode(data)

        # Write the cleaned data to a new JSON file
        with open(output_file, 'w', encoding='utf-8') as file:
            json.dump(cleaned_data, file, ensure_ascii=False, indent=4)

        print(f"Cleaned JSON file saved to {output_file}")

    except Exception as e:
        print(f"An error occurred: {e}")

# Example usage
input_file_path = 'recipes_final.json'  # Replace with your input JSON file path
output_file_path = 'final_recipes_cleaned.json'  # Replace with your output JSON file path
clean_json_unicode(input_file_path, output_file_path)
