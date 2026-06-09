import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:meal_planner/features/auth/views/welcome_screen.dart';
import 'package:meal_planner/features/dashboard/views/dashboard_screen.dart';
import 'package:meal_planner/features/inventory/views/inventory_screen.dart';
import 'package:meal_planner/features/orders/views/tracking_screen.dart';
import 'package:meal_planner/features/planner/views/planner_screen.dart';
import 'package:meal_planner/features/profile/views/profile_screen.dart';
import 'package:meal_planner/features/recipes/views/recipes_screen.dart';
import 'package:meal_planner/features/shopping_list/views/shopping_list_screen.dart';
import '../storage/auth_storage.dart';
import '../theme/theme.dart';

// Import screens (will create them next)

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (BuildContext context, GoRouterState state) async {
    final hasSession = await AuthStorage().hasSession();
    final isLoggingIn = state.uri.toString() == '/welcome';

    if (!hasSession && !isLoggingIn) {
      return '/welcome';
    }
    if (hasSession && isLoggingIn) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/welcome',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WelcomeScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return ShellNavigationLayout(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/inventory',
          builder: (context, state) => const InventoryScreen(),
        ),
        GoRoute(
          path: '/recipes',
          builder: (context, state) => const RecipesScreen(),
        ),
        GoRoute(
          path: '/planner',
          builder: (context, state) => const PlannerScreen(),
        ),
        GoRoute(
          path: '/shopping-list',
          builder: (context, state) => const ShoppingListScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/tracking/:orderId',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final orderIdStr = state.pathParameters['orderId'];
        final orderId = int.tryParse(orderIdStr ?? '0') ?? 0;
        return TrackingScreen(orderId: orderId);
      },
    ),
  ],
);

class ShellNavigationLayout extends StatelessWidget {
  final Widget child;

  const ShellNavigationLayout({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location == '/') return 0;
    if (location.startsWith('/inventory')) return 1;
    if (location.startsWith('/recipes')) return 2;
    if (location.startsWith('/planner')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0; // Default or fallback
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/inventory');
        break;
      case 2:
        context.go('/recipes');
        break;
      case 3:
        context.go('/planner');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIdx = _calculateSelectedIndex(context);
    final String location = GoRouterState.of(context).uri.toString();
    
    // Check if we should show the bottom bar (don't show on tracking, welcome)
    final showBottomBar = location != '/welcome' && !location.startsWith('/tracking');

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: child),
          if (showBottomBar)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    height: 80 + MediaQuery.of(context).padding.bottom,
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.85),
                      border: const Border(
                        top: BorderSide(color: Color(0x1A6D7B6C), width: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildNavItem(
                          index: 0,
                          icon: Icons.home,
                          label: 'Home',
                          isSelected: selectedIdx == 0,
                          context: context,
                        ),
                        _buildNavItem(
                          index: 1,
                          icon: Icons.inventory_2,
                          label: 'Inventory',
                          isSelected: selectedIdx == 1,
                          context: context,
                        ),
                        _buildNavItem(
                          index: 2,
                          icon: Icons.menu_book,
                          label: 'Recipes',
                          isSelected: selectedIdx == 2,
                          context: context,
                        ),
                        _buildNavItem(
                          index: 3,
                          icon: Icons.calendar_month,
                          label: 'Planner',
                          isSelected: selectedIdx == 3,
                          context: context,
                        ),
                        _buildNavItem(
                          index: 4,
                          icon: Icons.person,
                          label: 'Profile',
                          isSelected: selectedIdx == 4,
                          context: context,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () => _onItemTapped(index, context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 65,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primaryColor : AppColors.tertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primaryColor : AppColors.tertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
