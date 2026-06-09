# Implementation Plan - Meal Planner Flutter Frontend

We will build the Flutter frontend for the Meal Planner Application, ensuring pixel-perfect fidelity with the Stitch design system (project ID `7396449258035625541`) and integration with the backend APIs.

---

## User Review Required

> [!IMPORTANT]
> **Stitch Design Tokens Integration**:
> * **Colors**: 
>   - Primary: `#006E2F` (Deep Green) / Primary Container: `#22C55E` (Fresh Green)
>   - Secondary: `#9D4300` (Warm Orange) / Secondary Container: `#FD761A`
>   - Background: `#F8F9FF`
>   - Surface Container Low: `#EFF4FF`
>   - Text Primary: `#0B1C30` (Deep Slate)
> * **Typography**: We will configure standard `Inter` fonts as defined in the Stitch style sheet.
> * **Shapes**: Large containers/cards use a `20px` radius; buttons use a `12px` or pill radius.
>
> [!IMPORTANT]
> **API & Services Layer**:
> All HTTP communications will go through a dedicated API client using `Dio` with a base URL of `http://localhost:5001`. The client will use a JWT authentication interceptor that automatically reads and attaches the `Authorization: Bearer <token>` header from local storage.
>
> [!IMPORTANT]
> **Routing and Bottom Tab Bar**:
> We will configure `GoRouter` with ShellRoute to handle the persistency of the bottom navigation bar (Home, Inventory, Recipes, Planner, Profile).

---

## Open Questions

> [!NOTE]
> Since Stitch includes a Welcome/Splash screen with Sign Up and Login buttons, we will build a registration form, login form, and password reset dialog directly on top of the Welcome page using smooth sliding overlays or dedicated routes to keep the UI clean and matching the design.

---

## Proposed Changes

We will modify and create files inside `project/frontend/meal_planner`.

### Project Setup and Dependencies

#### [MODIFY] [pubspec.yaml](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/pubspec.yaml)
- Add dependencies: `flutter_bloc`, `go_router`, `dio`, `intl`, `shared_preferences`.
- Add dev_dependencies: `build_runner`, `freezed`, `freezed_annotation` (if model generation is needed).

---

### Core Layer (Theme, Network, Storage)

#### [NEW] [theme.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/core/theme/theme.dart)
- Define `ThemeData` with Inter font, Stitch custom color schemes, shadows, and radii.

#### [NEW] [dio_client.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/core/network/dio_client.dart)
- Configure `Dio` instances and attach authentication/logging interceptors.

#### [NEW] [auth_storage.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/core/storage/auth_storage.dart)
- Persist JWT access token and refresh token in shared preferences.

#### [NEW] [router.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/core/router/router.dart)
- Configure GoRouter routes for: Welcome/Auth, Shell (Dashboard, Inventory, Recipes, Planner, Profile), Order Tracking.

---

### Services Layer (API Abstractions)

#### [NEW] [auth_service.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/services/auth_service.dart)
- Implement `register`, `login`, `passwordResetRequest`, `passwordReset`.

#### [NEW] [grocery_service.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/services/grocery_service.dart)
- Implement `getGroceries`, `addGrocery`, `updateGrocery`, `deleteGrocery`.

#### [NEW] [recipe_service.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/services/recipe_service.dart)
- Implement `getRecipes`, `getRecipeDetails`, `createRecipe`, `updateRecipe`, `deleteRecipe`, `validateRecipe`, `consumeRecipe`.

#### [NEW] [meal_plan_service.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/services/meal_plan_service.dart)
- Implement `getMealPlans`, `getMealPlanDetails`, `createMealPlan`, `addMealPlanItem`, `updateMealPlan`, `deleteMealPlan`.

#### [NEW] [shopping_list_service.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/services/shopping_list_service.dart)
- Implement `getShoppingList`, `addCustomItem`, `updateItem`, `deleteItem`.

#### [NEW] [order_service.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/services/order_service.dart)
- Implement `addToCart`, `placeOrder`, `getOrders`, `getOrderDetails`, `getOrderTracking`, `updateOrderStatus`.

#### [NEW] [analytics_service.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/services/analytics_service.dart)
- Implement `getAnalytics`.

---

### Features & State Management (Bloc and Views)

#### [NEW] Features & View Files
1. **Welcome Screen**: [welcome_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/features/auth/views/welcome_screen.dart) (Slide carousel, SignUp/Login overlays).
2. **Dashboard Screen**: [dashboard_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/features/dashboard/views/dashboard_screen.dart) (Overview stats, quick actions, upcoming meals card).
3. **Inventory Screen**: [inventory_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/features/inventory/views/inventory_screen.dart) (Produce/Dairy/Protein chips filters, swipe actions, status progress).
4. **Recipes Screen**: [recipes_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/features/recipes/views/recipes_screen.dart) (Search, grid/list view toggles, favorite indicators, validate dialog).
5. **Planner Screen**: [planner_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/features/planner/views/planner_screen.dart) (Horizontal mon-sun selector, slot cards, save indicator micro-interaction).
6. **Shopping List Screen**: [shopping_list_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/features/shopping_list/views/shopping_list_screen.dart) (Categorized items, circular checkboxes, check item line-through animation, bottom summary card, order action).
7. **Order Tracking Screen**: [tracking_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/features/orders/views/tracking_screen.dart) (Estimated arrival card, route map placeholder, status progress timeline, driver profile with call/help controls).
8. **Profile Screen**: [profile_screen.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/features/profile/views/profile_screen.dart) (Rating bento-grid, list actions, log out).

#### [NEW] Bloc Implementations
- **AuthBloc**: Manages login/registration states and JWT session timeouts.
- **InventoryBloc**: Manages adding/updating/deleting stock levels and status changes.
- **RecipeBloc**: Fetches lists, handles recipe creation, ingredient validation checks.
- **MealPlanBloc**: Manages slots, updates planner, and triggers warning messages on shortage.
- **ShoppingListBloc**: Handles generating lists from planners, manual edits, and checkoffs.
- **OrderBloc**: Manages checkout, cart status, tracking history, and driver milestones.

---

### App Bootstrapper

#### [MODIFY] [main.dart](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/project/frontend/meal_planner/lib/main.dart)
- Initialize shared preferences, wrap app in MultiBlocProvider, and load GoRouter navigation configuration.

---

## Verification Plan

### Manual Verification
- Deploy and start the Node.js backend (`npm run dev`).
- Run the Flutter app in the emulator/simulator (`flutter run`).
- Validate login/registration, drag-and-drop meal planning warning checks, shopping list generations, order checkouts, and tracking progress updates.
