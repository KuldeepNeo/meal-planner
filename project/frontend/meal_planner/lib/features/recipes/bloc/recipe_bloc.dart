import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../services/recipe_service.dart';

abstract class RecipeEvent {}
class LoadRecipes extends RecipeEvent {}
class CreateRecipeEvent extends RecipeEvent {
  final String recipeName;
  final String? description;
  final String? instructions;
  final int servings;
  final List<RecipeIngredient> ingredients;
  CreateRecipeEvent({
    required this.recipeName,
    this.description,
    this.instructions,
    required this.servings,
    required this.ingredients,
  });
}
class DeleteRecipeEvent extends RecipeEvent {
  final int id;
  DeleteRecipeEvent({required this.id});
}
class ValidateRecipeEvent extends RecipeEvent {
  final int recipeId;
  ValidateRecipeEvent({required this.recipeId});
}
class ConsumeRecipeEvent extends RecipeEvent {
  final int recipeId;
  final int servings;
  ConsumeRecipeEvent({required this.recipeId, required this.servings});
}

abstract class RecipeState {}
class RecipeInitial extends RecipeState {}
class RecipeLoading extends RecipeState {}
class RecipesLoaded extends RecipeState {
  final List<Recipe> recipes;
  RecipesLoaded(this.recipes);
}
class RecipeError extends RecipeState {
  final String message;
  RecipeError(this.message);
}
class RecipeActionSuccess extends RecipeState {
  final String message;
  RecipeActionSuccess(this.message);
}
class RecipeValidated extends RecipeState {
  final RecipeValidationResult result;
  RecipeValidated(this.result);
}

class RecipeBloc extends Bloc<RecipeEvent, RecipeState> {
  final RecipeService _recipeService;

  RecipeBloc({RecipeService? recipeService})
      : _recipeService = recipeService ?? RecipeService(),
        super(RecipeInitial()) {
    on<LoadRecipes>((event, emit) async {
      emit(RecipeLoading());
      final recipes = await _recipeService.getRecipes();
      emit(RecipesLoaded(recipes));
    });

    on<CreateRecipeEvent>((event, emit) async {
      emit(RecipeLoading());
      final id = await _recipeService.createRecipe(
        recipeName: event.recipeName,
        description: event.description,
        instructions: event.instructions,
        servings: event.servings,
        ingredients: event.ingredients,
      );
      if (id != null) {
        final recipes = await _recipeService.getRecipes();
        emit(RecipeActionSuccess('Recipe created successfully'));
        emit(RecipesLoaded(recipes));
      } else {
        emit(RecipeError('Failed to create recipe'));
      }
    });

    on<DeleteRecipeEvent>((event, emit) async {
      emit(RecipeLoading());
      final success = await _recipeService.deleteRecipe(event.id);
      if (success) {
        final recipes = await _recipeService.getRecipes();
        emit(RecipeActionSuccess('Recipe deleted successfully'));
        emit(RecipesLoaded(recipes));
      } else {
        emit(RecipeError('Failed to delete recipe'));
      }
    });

    on<ValidateRecipeEvent>((event, emit) async {
      emit(RecipeLoading());
      final result = await _recipeService.validateRecipe(event.recipeId);
      if (result != null) {
        emit(RecipeValidated(result));
      } else {
        emit(RecipeError('Failed to validate recipe'));
      }
    });

    on<ConsumeRecipeEvent>((event, emit) async {
      emit(RecipeLoading());
      final success = await _recipeService.consumeRecipe(event.recipeId, event.servings);
      if (success) {
        final recipes = await _recipeService.getRecipes();
        emit(RecipeActionSuccess('Recipe consumed, inventory updated'));
        emit(RecipesLoaded(recipes));
      } else {
        emit(RecipeError('Failed to consume recipe'));
      }
    });
  }
}
