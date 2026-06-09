import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/router/router.dart';
import 'core/theme/theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/inventory/bloc/inventory_bloc.dart';
import 'features/recipes/bloc/recipe_bloc.dart';
import 'features/planner/bloc/meal_plan_bloc.dart';
import 'features/shopping_list/bloc/shopping_list_bloc.dart';
import 'features/orders/bloc/order_bloc.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc()..add(CheckSession()),
        ),
        BlocProvider<InventoryBloc>(
          create: (context) => InventoryBloc(),
        ),
        BlocProvider<RecipeBloc>(
          create: (context) => RecipeBloc(),
        ),
        BlocProvider<MealPlanBloc>(
          create: (context) => MealPlanBloc(),
        ),
        BlocProvider<ShoppingListBloc>(
          create: (context) => ShoppingListBloc(),
        ),
        BlocProvider<OrderBloc>(
          create: (context) => OrderBloc(),
        ),
      ],
      child: MaterialApp.router(
        title: 'Zest Meal Planner',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        routerConfig: appRouter,
      ),
    );
  }
}
