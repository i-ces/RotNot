import os
from pathlib import Path

from dotenv import load_dotenv
from huggingface_hub import InferenceClient

# Load .env file from project root or backend folder
env_paths = [
    Path(__file__).parent.parent / ".env",  # Project root
    Path(__file__).parent.parent / "backend" / ".env",  # Backend folder
  ]

for env_path in env_paths:
    if env_path.exists():
        load_dotenv(env_path)
        break

# Set Hugging Face token 
HF_TOKEN = os.getenv("HF_TOKEN")


class RecipeGenerator:
    
    def __init__(self, model_name: str = "meta-llama/Llama-3.1-70B-Instruct"):
      
        self.model_name = model_name
        self.client = InferenceClient(token=HF_TOKEN)
        
    def _generate_response(self, prompt: str, max_new_tokens: int = 1032) -> str:
      
        messages = [{"role": "user", "content": prompt}]
        
        response = self.client.chat_completion(
            model=self.model_name,
            messages=messages,
            max_tokens=max_new_tokens,
            temperature=0.7,
            top_p=0.9
        )
        
        return response.choices[0].message.content.strip()
    
    def get_recipe_names(self, food_items: list[str], num_recipes: int = 3) -> list[str]:

        ingredients_str = ", ".join(food_items)
        
        prompt = f"""You are a professional chef. Given these ingredients: {ingredients_str}

Suggest exactly {num_recipes} recipe names that can be made using some or all of these ingredients.
Return ONLY the recipe names, one per line, numbered.
Do not include descriptions or additional text."""

        response = self._generate_response(prompt, max_new_tokens=200)
        
        # Parse the response to extract recipe names
        lines = response.strip().split("\n")
        recipe_names = []
        
        for line in lines:
            line = line.strip()
            if line:
                # Remove numbering like "1.", "1)", "1:" etc.
                cleaned = line.lstrip("0123456789.-) :")
                if cleaned:
                    recipe_names.append(cleaned.strip())
        
        return recipe_names[:num_recipes]
    
    def get_recipe_description(self, recipe_name: str, available_ingredients: list[str] = None) -> dict:
  
        ingredient_context = ""
        if available_ingredients:
            ingredient_context = f"\nAvailable ingredients: {', '.join(available_ingredients)}"
        
        prompt = f"""You are a professional chef. Provide a complete recipe for: {recipe_name}{ingredient_context}

Please include:
1. Recipe name
2. Brief description
3. Servings
4. Prep time and cook time
5. Complete list of ingredients with measurements
6. Step-by-step cooking instructions
7. Any helpful tips

Format the response clearly with sections."""

        response = self._generate_response(prompt, max_new_tokens=1024)
        
        return {
            "recipe_name": recipe_name,
            "full_description": response
        }


# Create a global instance for easy access
_generator = None


def get_generator() -> RecipeGenerator:
    #Get or create the global recipe generator instance
    global _generator
    if _generator is None:
        _generator = RecipeGenerator()
    return _generator


def generate_recipe_names(food_items: list[str], num_recipes: int = 3) -> list[str]:
    #Generate recipe name suggestions from food items.
    generator = get_generator()
    return generator.get_recipe_names(food_items, num_recipes)


def get_full_recipe(recipe_name: str, available_ingredients: list[str] = None) -> dict:
    #Get the full recipe description for a specific recipe.
    generator = get_generator()
    return generator.get_recipe_description(recipe_name, available_ingredients)


     
# Test block 
# if __name__ == "__main__":
   
    # test_ingredients = ["chicken", "tomato", "garlic", "basil"]
    # test_recipe_name = "Chicken Chilli"
    
    # print(" Testing Recipe Name Generation ")
    # print(f"Ingredients: {test_ingredients}")
    # names = generate_recipe_names(test_ingredients)
    # for i, name in enumerate(names, 1):
    #     print(f"  {i}. {name}")
    
    # print("\n Testing Full Recipe Generation ")
    # print(f"Recipe: {test_recipe_name}")
    # recipe = get_full_recipe(test_recipe_name)
    # print(recipe['full_description'])
 