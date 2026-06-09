import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/meal_plan_bloc.dart';
import '../../recipes/bloc/recipe_bloc.dart';
import '../../../core/theme/theme.dart';
import '../../../services/meal_plan_service.dart';
import '../../../services/recipe_service.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});

  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _weekDays;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Compute current week's days starting Monday
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    _weekDays = List.generate(7, (i) => monday.add(Duration(days: i)));
    _selectedDate = _weekDays[0];

    // Load active meal plan & recipes
    context.read<MealPlanBloc>().add(LoadMealPlans());
    context.read<RecipeBloc>().add(LoadRecipes());
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _triggerSaveAnimation() {
    setState(() {
      _isSaving = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    });
  }

  void _showAddRecipeModal(int planId, String mealType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
              const Text(
                'Select Recipe to Add',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              BlocBuilder<RecipeBloc, RecipeState>(
                builder: (context, state) {
                  if (state is RecipeLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
                  } else if (state is RecipesLoaded) {
                    final recipes = state.recipes;
                    if (recipes.isEmpty) {
                      return const Center(
                        child: Text(
                          'No recipes available. Create one in the Recipes tab.',
                          style: TextStyle(fontFamily: 'Inter', color: AppColors.tertiary),
                        ),
                      );
                    }
                    return SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: recipes.length,
                        itemBuilder: (context, index) {
                          final recipe = recipes[index];
                          return ListTile(
                            title: Text(recipe.recipeName),
                            subtitle: Text('${recipe.servings} Servings'),
                            trailing: const Icon(Icons.add_circle_outline, color: AppColors.primaryColor),
                            onTap: () {
                              _triggerSaveAnimation();
                              context.read<MealPlanBloc>().add(
                                    AddMealPlanItemEvent(
                                      mealPlanId: planId,
                                      mealDate: DateFormat('yyyy-MM-dd').format(_selectedDate),
                                      mealType: mealType.toUpperCase(),
                                      recipeId: recipe.id,
                                      servingCount: recipe.servings,
                                    ),
                                  );
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    );
                  } else {
                    return const Text('Failed to load recipes.');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MealPlanBloc, MealPlanState>(
      listener: (context, state) {
        if (state is MealPlansLoaded && state.warningMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.warningMessage!),
              backgroundColor: AppColors.secondary,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // Top App Bar
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.menu, color: AppColors.primaryColor),
                          onPressed: () {},
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Zest',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryColor,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Auto-save status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isSaving ? Icons.sync : Icons.cloud_done,
                                size: 14,
                                color: AppColors.primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isSaving ? 'Saving...' : 'Saved',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.search, color: AppColors.tertiary),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Horizontal Day Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                height: 85,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _weekDays.length,
                  itemBuilder: (context, index) {
                    final day = _weekDays[index];
                    final isSelected = DateFormat('yyyy-MM-dd').format(day) == DateFormat('yyyy-MM-dd').format(_selectedDate);
                    return GestureDetector(
                      onTap: () => _onDateSelected(day),
                      child: Container(
                        width: 58,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primaryColor : AppColors.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected ? AppTheme.cardShadow : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('E').format(day).toUpperCase(),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white.withOpacity(0.8) : AppColors.tertiary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('d').format(day),
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isSelected ? Colors.white : AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Meal list content
            Expanded(
              child: BlocBuilder<MealPlanBloc, MealPlanState>(
                builder: (context, state) {
                  if (state is MealPlanLoading) {
                    return const Center(child: CircularProgressIndicator(color: AppColors.primaryColor));
                  } else if (state is MealPlansLoaded) {
                    final plan = state.activePlan;
                    if (plan == null) {
                      // If no active plan, prompt to create one
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'No active weekly meal plan.',
                              style: TextStyle(fontFamily: 'Inter', color: AppColors.tertiary),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                final today = DateFormat('yyyy-MM-dd').format(_weekDays[0]);
                                final end = DateFormat('yyyy-MM-dd').format(_weekDays[6]);
                                context.read<MealPlanBloc>().add(CreateMealPlanEvent(startDate: today, endDate: end));
                              },
                              child: const Text('Create Meal Plan'),
                            ),
                          ],
                        ),
                      );
                    }

                    // Filter planned items for selected day
                    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
                    final dayItems = plan.items.where((item) => item.mealDate == dateStr).toList();

                    return ListView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 100.0),
                      children: [
                        _buildMealSlot(plan.id, 'Breakfast', dayItems.where((i) => i.mealType == 'BREAKFAST').toList()),
                        const SizedBox(height: 20),
                        _buildMealSlot(plan.id, 'Lunch', dayItems.where((i) => i.mealType == 'LUNCH').toList()),
                        const SizedBox(height: 20),
                        _buildMealSlot(plan.id, 'Dinner', dayItems.where((i) => i.mealType == 'DINNER').toList()),
                        const SizedBox(height: 20),
                        _buildMealSlot(plan.id, 'Snacks', dayItems.where((i) => i.mealType == 'SNACKS').toList()),
                      ],
                    );
                  } else {
                    return const Center(child: Text('Failed to load planner.'));
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSlot(int planId, String title, List<MealPlanItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            const Text(
              '450 kcal',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.tertiary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (items.isEmpty)
          GestureDetector(
            onTap: () => _showAddRecipeModal(planId, title),
            child: Container(
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppColors.outlineVariant.withOpacity(0.5),
                  width: 2,
                  style: BorderStyle.solid, // Note: Flutter doesn't have native dashed border without custom painter, but dashed-style solid is fine.
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.add, color: AppColors.primaryColor, size: 20),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add $title Recipe',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          ...items.map(
            (item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.outlineVariant.withOpacity(0.3), width: 1),
                boxShadow: AppTheme.cardShadow,
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=200&auto=format&fit=crop',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.recipeName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Icon(Icons.timer, size: 12, color: AppColors.tertiary),
                            SizedBox(width: 4),
                            Text(
                              '15 mins',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                color: AppColors.tertiary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.drag_indicator, color: AppColors.outlineVariant),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
