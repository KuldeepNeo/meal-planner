import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/recipe_bloc.dart';
import '../../../core/theme/theme.dart';
import '../../../services/recipe_service.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _isGrid = true;

  @override
  void initState() {
    super.initState();
    context.read<RecipeBloc>().add(LoadRecipes());
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  String _getRecipeCategory(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('egg') || lowerName.contains('pancake') || lowerName.contains('protein cup') || lowerName.contains('breakfast')) {
      return 'Breakfast';
    }
    if (lowerName.contains('salad') || lowerName.contains('bowl') || lowerName.contains('lunch')) {
      return 'Lunch';
    }
    if (lowerName.contains('salmon') || lowerName.contains('pasta') || lowerName.contains('chicken') || lowerName.contains('thai') || lowerName.contains('dinner')) {
      return 'Dinner';
    }
    return 'Healthy';
  }

  String _getRecipeImage(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('salmon')) {
      return 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=400&auto=format&fit=crop';
    }
    if (lowerName.contains('salad') || lowerName.contains('harvest')) {
      return 'https://images.unsplash.com/photo-1540420773420-3366772f4999?q=80&w=400&auto=format&fit=crop';
    }
    if (lowerName.contains('pasta')) {
      return 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=400&auto=format&fit=crop';
    }
    if (lowerName.contains('protein cup') || lowerName.contains('yogurt')) {
      return 'https://images.unsplash.com/photo-1488477181946-6428a0291777?q=80&w=400&auto=format&fit=crop';
    }
    return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=400&auto=format&fit=crop';
  }

  void _showAddRecipeDialog() {
    final nameController = TextEditingController();
    final servingsController = TextEditingController(text: '2');
    final descController = TextEditingController();
    final instructionsController = TextEditingController();
    
    // Simple ingredients list state
    List<RecipeIngredient> ingredients = [];
    final ingNameController = TextEditingController();
    final ingQtyController = TextEditingController();
    final ingUnitController = TextEditingController(text: 'pcs');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Create Recipe'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Recipe Name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: servingsController,
                        decoration: const InputDecoration(labelText: 'Servings'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: descController,
                        decoration: const InputDecoration(labelText: 'Description'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructionsController,
                  decoration: const InputDecoration(labelText: 'Instructions'),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: ingNameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50,
                      child: TextField(
                        controller: ingQtyController,
                        decoration: const InputDecoration(labelText: 'Qty'),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: ingUnitController,
                        decoration: const InputDecoration(labelText: 'Unit'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    final name = ingNameController.text.trim();
                    final qty = double.tryParse(ingQtyController.text) ?? 1.0;
                    final unit = ingUnitController.text.trim();
                    if (name.isNotEmpty) {
                      setStateDialog(() {
                        ingredients.add(RecipeIngredient(ingredientName: name, quantity: qty, unit: unit));
                        ingNameController.clear();
                        ingQtyController.clear();
                      });
                    }
                  },
                  child: const Text('Add Ingredient'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: ingredients.map((ing) => Chip(
                    label: Text('${ing.ingredientName} (${ing.quantity} ${ing.unit})'),
                    onDeleted: () {
                      setStateDialog(() {
                        ingredients.remove(ing);
                      });
                    },
                  )).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                final servings = int.tryParse(servingsController.text) ?? 2;
                if (name.isNotEmpty && ingredients.isNotEmpty) {
                  context.read<RecipeBloc>().add(
                    CreateRecipeEvent(
                      recipeName: name,
                      servings: servings,
                      description: descController.text.trim(),
                      instructions: instructionsController.text.trim(),
                      ingredients: ingredients,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showRecipeDetails(Recipe recipe) {
    context.read<RecipeBloc>().add(ValidateRecipeEvent(recipeId: recipe.id));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BlocBuilder<RecipeBloc, RecipeState>(
          builder: (context, state) {
            bool? isValid;
            List<String> missing = [];

            if (state is RecipeValidated) {
              isValid = state.result.valid;
              missing = state.result.missingIngredients;
            }

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          recipe.recipeName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (recipe.description != null) ...[
                    Text(
                      recipe.description!,
                      style: const TextStyle(fontFamily: 'Inter', color: AppColors.tertiary),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 18, color: AppColors.tertiary),
                      const SizedBox(width: 4),
                      const Text('20 mins', style: TextStyle(color: AppColors.tertiary)),
                      const SizedBox(width: 16),
                      const Icon(Icons.person, size: 18, color: AppColors.tertiary),
                      const SizedBox(width: 4),
                      Text('${recipe.servings} Servings', style: const TextStyle(color: AppColors.tertiary)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Ingredients', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  ...recipe.ingredients.map((ing) {
                    final isMissing = missing.any((m) => m.toLowerCase() == ing.ingredientName.toLowerCase());
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ing.ingredientName,
                            style: TextStyle(
                              color: isMissing ? AppColors.error : AppColors.onSurface,
                              decoration: isMissing ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          Text('${ing.quantity} ${ing.unit}', style: const TextStyle(color: AppColors.tertiary)),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 24),
                  if (isValid != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isValid ? AppColors.primaryContainer.withOpacity(0.1) : AppColors.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isValid ? Icons.check_circle : Icons.warning,
                            color: isValid ? AppColors.primaryColor : AppColors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isValid 
                                  ? 'All ingredients in stock!' 
                                  : 'Missing ingredients: ${missing.join(', ')}',
                              style: TextStyle(
                                color: isValid ? AppColors.primaryColor : AppColors.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            context.read<RecipeBloc>().add(DeleteRecipeEvent(id: recipe.id));
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                          child: const Text('Delete'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isValid == true 
                              ? () {
                                  context.read<RecipeBloc>().add(ConsumeRecipeEvent(recipeId: recipe.id, servings: recipe.servings));
                                  Navigator.pop(context);
                                }
                              : null,
                          child: const Text('Cook Now'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header
              SliverAppBar(
                pinned: true,
                floating: true,
                expandedHeight: 70,
                backgroundColor: AppColors.surface.withOpacity(0.85),
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.menu, color: AppColors.primaryColor),
                  onPressed: () {},
                ),
                title: const Text(
                  'Zest',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                    letterSpacing: -1,
                  ),
                ),
                actions: [
                  IconButton(
                    icon: Icon(_isGrid ? Icons.grid_view : Icons.view_agenda, color: AppColors.primaryColor),
                    onPressed: () {
                      setState(() {
                        _isGrid = !_isGrid;
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.search, color: AppColors.primaryColor),
                    onPressed: () {},
                  ),
                ],
              ),

              // Search & Filter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search, color: AppColors.outline),
                          hintText: 'Search delicious recipes...',
                          fillColor: AppColors.surfaceContainerLow,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 38,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            _buildFilterChip('All'),
                            _buildFilterChip('Breakfast'),
                            _buildFilterChip('Lunch'),
                            _buildFilterChip('Dinner'),
                            _buildFilterChip('Healthy'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Recipes items section
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 100.0),
                sliver: BlocBuilder<RecipeBloc, RecipeState>(
                  builder: (context, state) {
                    if (state is RecipeLoading) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator(color: AppColors.primaryColor)),
                      );
                    } else if (state is RecipesLoaded) {
                      final recipes = state.recipes.where((recipe) {
                        final matchesSearch = recipe.recipeName.toLowerCase().contains(_searchQuery);
                        final itemCat = _getRecipeCategory(recipe.recipeName);
                        final matchesCategory = _selectedCategory == 'All' || itemCat == _selectedCategory;
                        return matchesSearch && matchesCategory;
                      }).toList();

                      if (recipes.isEmpty) {
                        return const SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Text(
                              'No recipes found.',
                              style: TextStyle(fontFamily: 'Inter', color: AppColors.tertiary),
                            ),
                          ),
                        );
                      }

                      if (_isGrid) {
                        return SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final recipe = recipes[index];
                              return _buildRecipeGridCard(recipe);
                            },
                            childCount: recipes.length,
                          ),
                        );
                      } else {
                        return SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final recipe = recipes[index];
                              return _buildRecipeListCard(recipe);
                            },
                            childCount: recipes.length,
                          ),
                        );
                      }
                    } else {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'Failed to load recipes.',
                            style: TextStyle(fontFamily: 'Inter', color: AppColors.error),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),

          // Floating Action Button
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              onPressed: _showAddRecipeDialog,
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String category) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => _onCategorySelected(category),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          category,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeGridCard(Recipe recipe) {
    final imgUrl = _getRecipeImage(recipe.recipeName);
    return InkWell(
      onTap: () => _showRecipeDetails(recipe),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3), width: 1),
          boxShadow: AppTheme.cardShadow,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Image.network(
                imgUrl,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.recipeName,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 14, color: AppColors.tertiary),
                      const SizedBox(width: 2),
                      const Text('20m', style: TextStyle(fontSize: 11, color: AppColors.tertiary)),
                      const SizedBox(width: 8),
                      const Icon(Icons.person, size: 14, color: AppColors.tertiary),
                      const SizedBox(width: 2),
                      Text('${recipe.servings} serv', style: const TextStyle(fontSize: 11, color: AppColors.tertiary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeListCard(Recipe recipe) {
    final imgUrl = _getRecipeImage(recipe.recipeName);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        onTap: () => _showRecipeDetails(recipe),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3), width: 1),
            boxShadow: AppTheme.cardShadow,
          ),
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imgUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.recipeName,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule, size: 14, color: AppColors.tertiary),
                        const SizedBox(width: 2),
                        const Text('20 mins', style: TextStyle(fontSize: 12, color: AppColors.tertiary)),
                        const SizedBox(width: 16),
                        const Icon(Icons.person, size: 14, color: AppColors.tertiary),
                        const SizedBox(width: 2),
                        Text('${recipe.servings} Servings', style: const TextStyle(fontSize: 12, color: AppColors.tertiary)),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.tertiary),
            ],
          ),
        ),
      ),
    );
  }
}
