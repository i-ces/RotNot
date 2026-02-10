"""
Recipe Generation API Service
FastAPI server that generates recipe suggestions using LLM
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

from receipe import generate_recipe_names, get_full_recipe

# Initialize FastAPI app
app = FastAPI(
    title="RotNot Recipe API",
    description="Generate recipe suggestions from available ingredients using AI",
    version="1.0.0"
)

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Request/Response Models
class RecipeNamesRequest(BaseModel):
    ingredients: list[str]
    num_recipes: int = 3


class RecipeNamesResponse(BaseModel):
    success: bool
    recipes: list[str]
    message: str = ""


class FullRecipeRequest(BaseModel):
    recipe_name: str
    available_ingredients: list[str] | None = None


class FullRecipeResponse(BaseModel):
    success: bool
    recipe_name: str
    full_description: str
    message: str = ""


# Endpoints
@app.get("/")
async def root():
    return {"message": "Recipe Generation API is running", "status": "ok"}


@app.get("/health")
async def health():
    return {"status": "healthy", "service": "recipe-generator"}


@app.post("/recipes/suggest", response_model=RecipeNamesResponse)
async def suggest_recipes(data: RecipeNamesRequest):
    """
    Generate recipe name suggestions from a list of ingredients.
    
    Body: {"ingredients": ["chicken", "tomato"], "num_recipes": 3}
    Returns: list of suggested recipe names
    """
    try:
        if not data.ingredients:
            raise HTTPException(status_code=400, detail="No ingredients provided")
        
        print(f"Generating recipes for: {data.ingredients}")
        
        recipe_names = generate_recipe_names(
            food_items=data.ingredients,
            num_recipes=data.num_recipes
        )
        
        print(f"Generated recipes: {recipe_names}")
        
        return RecipeNamesResponse(
            success=True,
            recipes=recipe_names,
            message=f"Generated {len(recipe_names)} recipe suggestion(s)"
        )
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"Recipe generation error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Recipe generation failed: {str(e)}")


@app.post("/recipes/full", response_model=FullRecipeResponse)
async def get_recipe_details(data: FullRecipeRequest):
    """
    Get full recipe details for a specific recipe name.
    
    Body: {"recipe_name": "Chicken Parmesan", "available_ingredients": ["chicken", "cheese"]}
    Returns: complete recipe with ingredients and instructions
    """
    try:
        if not data.recipe_name:
            raise HTTPException(status_code=400, detail="No recipe name provided")
        
        print(f"Getting full recipe for: {data.recipe_name}")
        
        recipe = get_full_recipe(
            recipe_name=data.recipe_name,
            available_ingredients=data.available_ingredients
        )
        
        return FullRecipeResponse(
            success=True,
            recipe_name=recipe["recipe_name"],
            full_description=recipe["full_description"],
            message="Recipe generated successfully"
        )
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"Full recipe error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Recipe fetch failed: {str(e)}")


@app.post("/recipes/surprise", response_model=FullRecipeResponse)
async def surprise_recipe(data: RecipeNamesRequest):
    """
    Generate a random recipe from all available ingredients (Surprise Me feature).
    
    Body: {"ingredients": ["chicken", "tomato", "garlic"], "num_recipes": 1}
    Returns: a complete recipe using the ingredients
    """
    try:
        if not data.ingredients:
            raise HTTPException(status_code=400, detail="No ingredients provided")
        
        print(f"Surprise recipe with: {data.ingredients}")
        
        # First get a recipe suggestion
        recipe_names = generate_recipe_names(
            food_items=data.ingredients,
            num_recipes=1
        )
        
        if not recipe_names:
            raise HTTPException(status_code=404, detail="Could not generate a recipe suggestion")
        
        recipe_name = recipe_names[0]
        
        # Then get the full recipe
        recipe = get_full_recipe(
            recipe_name=recipe_name,
            available_ingredients=data.ingredients
        )
        
        return FullRecipeResponse(
            success=True,
            recipe_name=recipe["recipe_name"],
            full_description=recipe["full_description"],
            message="Surprise recipe generated!"
        )
    
    except HTTPException:
        raise
    except Exception as e:
        print(f"Surprise recipe error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Surprise recipe failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    print("Starting Recipe API on http://0.0.0.0:8001")
    print("Docs: http://0.0.0.0:8001/docs")
    uvicorn.run(app, host="0.0.0.0", port=8001)
