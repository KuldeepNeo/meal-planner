import '../core/network/dio_client.dart';

class RecipeIngredient {
  final String ingredientName;
  final double quantity;
  final String unit;

  RecipeIngredient({
    required this.ingredientName,
    required this.quantity,
    required this.unit,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredientName: json['ingredientName'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredientName': ingredientName,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class Recipe {
  final int id;
  final String recipeName;
  final String? description;
  final String? instructions;
  final int servings;
  final List<RecipeIngredient> ingredients;

  Recipe({
    required this.id,
    required this.recipeName,
    this.description,
    this.instructions,
    required this.servings,
    this.ingredients = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    var ingList = json['ingredients'] as List?;
    return Recipe(
      id: json['id'] ?? 0,
      recipeName: json['recipeName'] ?? '',
      description: json['description'],
      instructions: json['instructions'],
      servings: json['servings'] ?? 1,
      ingredients: ingList != null
          ? ingList.map((i) => RecipeIngredient.fromJson(i)).toList()
          : [],
    );
  }
}

class RecipeValidationResult {
  final bool valid;
  final List<String> missingIngredients;

  RecipeValidationResult({
    required this.valid,
    required this.missingIngredients,
  });

  factory RecipeValidationResult.fromJson(Map<String, dynamic> json) {
    var missing = json['missingIngredients'] as List?;
    return RecipeValidationResult(
      valid: json['valid'] ?? false,
      missingIngredients: missing != null ? List<String>.from(missing) : [],
    );
  }
}

class RecipeService {
  final DioClient _dioClient;

  RecipeService({DioClient? dioClient}) : _dioClient = dioClient ?? DioClient();

  Future<List<Recipe>> getRecipes() async {
    try {
      final response = await _dioClient.dio.get('/api/recipes');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Recipe.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<Recipe?> getRecipeDetails(int id) async {
    try {
      final response = await _dioClient.dio.get('/api/recipes/$id');
      if (response.statusCode == 200) {
        return Recipe.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<int?> createRecipe({
    required String recipeName,
    String? description,
    String? instructions,
    required int servings,
    required List<RecipeIngredient> ingredients,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/recipes',
        data: {
          'recipeName': recipeName,
          if (description != null) 'description': description,
          if (instructions != null) 'instructions': instructions,
          'servings': servings,
          'ingredients': ingredients.map((i) => i.toJson()).toList(),
        },
      );
      if (response.statusCode == 201) {
        return response.data['id'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteRecipe(int id) async {
    try {
      final response = await _dioClient.dio.delete('/api/recipes/$id');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<RecipeValidationResult?> validateRecipe(int recipeId) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/recipes/validate',
        data: {'recipeId': recipeId},
      );
      if (response.statusCode == 200) {
        return RecipeValidationResult.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> consumeRecipe(int recipeId, int servings) async {
    try {
      final response = await _dioClient.dio.post(
        '/api/recipes/$recipeId/consume',
        data: {'servings': servings},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
