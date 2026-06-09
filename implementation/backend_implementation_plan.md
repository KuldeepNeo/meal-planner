# Implementation Plan - Meal Planner Backend

The goal of this task is to implement a complete, robust, and clean backend for the Meal Planner Application using Node.js (v24.16.0), Express.js (v5.2.1), and SQLite (v3.52.0).

---

## User Review Required

> [!IMPORTANT]
> The database schema requires SQLite. We will use `better-sqlite3` or standard `sqlite3`. `better-sqlite3` is typically preferred for synchronous execution in Node.js, but standard `sqlite3` is also very common. We plan to use `better-sqlite3` for simplicity, performance, and synchronous query execution which makes transaction management straightforward.
>
> [!IMPORTANT]
> We will add several non-contract endpoints to allow executing and verifying specific workflows mentioned in the KPIs, such as:
> 1. `POST /api/recipes/:id/consume` to execute the recipe consumption workflow (decreasing inventory quantities and logging `InventoryTransaction`).
> 2. `PUT /api/orders/:id/status` to update order status (e.g., to `DELIVERED`, which automatically updates the inventory and logs `InventoryTransaction` for purchased items).
> 3. `GET /api/analytics` to calculate and retrieve the business metrics and KPI rates.

---

## Open Questions

> [!NOTE]
> Since standard JWT authentication is required, we will generate a JWT (valid for 15 minutes) and a long-lived refresh token upon successful registration/login. We will store these sessions in the `UserSession` table and validate them on protected endpoints.
>
> [!NOTE]
> For password reset, since there's no actual mail server integration requested, we will log the reset links to the console/terminal during testing/execution and provide the tokens in-memory or in the database for the verification step.

---

## Proposed Changes

We will create a `backend` folder under the workspace root.

### Backend Infrastructure & Configurations

#### [NEW] [package.json](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/package.json)
- Define scripts: `npm start`, `npm run dev`, `npm test`, `npm run db:init`, `npm run db:seed`.
- Dependencies: `express`, `better-sqlite3`, `bcryptjs`, `jsonwebtoken`, `dotenv`, `cors`.
- DevDependencies: `jest`, `supertest`, `nodemon`.

#### [NEW] [.env](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/.env)
- Configuration variables: `PORT=5001`, `JWT_SECRET=supersecretjwtkey`, `DB_FILE=database.sqlite`.

#### [NEW] [database.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/config/database.js)
- Establishes connection to the SQLite database.
- Enforces foreign key constraints using `PRAGMA foreign_keys = ON`.

#### [NEW] [db.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/models/db.js)
- Database schema migrations and creation of tables (User, UserSession, PasswordResetToken, GroceryItem, Recipe, RecipeIngredient, MealPlan, MealPlanItem, ShoppingList, ShoppingListItem, Vendor, CustomerOrder, OrderItem, OrderTrackingEvent, InventoryTransaction, UserMetric).
- Creates indexes for optimal lookup performance.

---

### Middlewares

#### [NEW] [auth.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/middleware/auth.js)
- Authenticates JWT tokens from the `Authorization` header (`Bearer <token>`).
- Rejects requests without valid tokens or with expired sessions.

#### [NEW] [error.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/middleware/error.js)
- Global error-handling middleware that returns formatted error messages.

#### [NEW] [validate.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/middleware/validate.js)
- Validates request payloads against rules (e.g. required fields, valid formatting, non-negative quantities, servings > 0, etc.) and returns standard 400 Bad Request error response if validation fails.

---

### API Routers and Controllers

#### [NEW] [auth.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/routes/auth.js)
- Handlers for:
  - `POST /api/auth/register` (hashing password, saving user, returning success)
  - `POST /api/auth/login` (verifying credentials, generating tokens, saving session)
  - `POST /api/auth/password-reset-request` (generating reset token)
  - `POST /api/auth/password-reset` (updating password with valid token)

#### [NEW] [grocery.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/routes/grocery.js)
- Handlers for:
  - `GET /api/groceries` (retrieving all user grocery inventory, dynamically computing and saving status: `IN_STOCK`, `LOW_STOCK`, `OUT_OF_STOCK`, `EXPIRING_SOON`)
  - `POST /api/groceries` (creating inventory item, setting initial stock status)
  - `PUT /api/groceries/:id` (updating quantity/threshold/expiry and recalculating status)
  - `DELETE /api/groceries/:id` (deleting inventory item)

#### [NEW] [recipe.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/routes/recipe.js)
- Handlers for:
  - `GET /api/recipes` and `GET /api/recipes/:id`
  - `POST /api/recipes` (saving recipe and ingredients list)
  - `PUT /api/recipes/:id`
  - `DELETE /api/recipes/:id`
  - `POST /api/recipes/validate` (checks if all recipe ingredients exist in inventory with sufficient quantity)
  - `POST /api/recipes/:id/consume` (custom endpoint to simulate consumption)

#### [NEW] [mealPlan.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/routes/mealPlan.js)
- Handlers for:
  - `GET /api/meal-plans` and `GET /api/meal-plans/:id`
  - `POST /api/meal-plans` (daily/weekly boundary initialization)
  - `POST /api/meal-plans/:id/items` (creates meal slot assignment, includes warning header/field if ingredients are insufficient)
  - `PUT /api/meal-plans/:id`
  - `DELETE /api/meal-plans/:id`

#### [NEW] [shoppingList.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/routes/shoppingList.js)
- Handlers for:
  - `GET /api/shopping-list` (checks upcoming meal plans, aggregates ingredient demands, compares to current inventory, aggregates duplicate entries, and returns generated/saved shopping list)
  - `POST /api/shopping-list/custom-item` (adds custom items to shopping list)
  - `PUT /api/shopping-list/items/:id` (manually updates quantity/attributes of list items)
  - `DELETE /api/shopping-list/items/:id` (removes item from shopping list)

#### [NEW] [order.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/routes/order.js)
- Handlers for:
  - `POST /api/orders/cart` (caches selected shopping list items)
  - `POST /api/orders` (places order, validates deliveryAddress and paymentMethod, maps items to `OrderItem` and clears cart)
  - `GET /api/orders` and `GET /api/orders/:id`
  - `GET /api/orders/:id/tracking` (retrieves delivery milestones and statuses)
  - `PUT /api/orders/:id/status` (custom: progresses order status; if `DELIVERED`, increases matching grocery inventory items and logs `InventoryTransaction`)

#### [NEW] [analytics.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/routes/analytics.js)
- Handlers for:
  - `GET /api/analytics` (calculates and returns values for the 11 business KPIs: Weekly Meal Plan Rate, Grocery Tracking Usage, Recipe Creation Rate, Grocery Order Conversion, Retention, average meal plans, shopping list generation rate, inventory accuracy, order completion rate, food waste reduction, active users growth)

#### [NEW] [app.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/app.js)
- Orchestrates express, middleware bindings, and routing.

#### [NEW] [server.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/src/server.js)
- Boots the server listening on configured port.

---

### Scripts

#### [NEW] [initDb.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/scripts/initDb.js)
- CLI script to initialize the SQLite database tables.

#### [NEW] [seedDb.js](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/scripts/seedDb.js)
- Populates vendors and initial test accounts / assets.

#### [NEW] [README.md](file:///Users/neo/Desktop/Vibe%20Coding%20Training/vibe_projects/meal-planner/backend/README.md)
- Complete deployment, config, setup, and testing documentation.

---

## Verification Plan

### Automated Tests
We will execute the complete test suite using Jest and Supertest.
- Commands:
  ```bash
  npm run db:init
  npm test
  ```
- The test suite will verify:
  1. Auth endpoints (registration, duplicate checks, login, password reset).
  2. Grocery endpoints (adding items, stock statuses `IN_STOCK`, `LOW_STOCK`, `OUT_OF_STOCK`, `EXPIRING_SOON`, validation of negative values and invalid dates).
  3. Recipe endpoints (creation, missing ingredients check, validation).
  4. Meal plan creation and ingredient validation warnings.
  5. Shopping list generation, custom items addition, duplicate aggregation.
  6. Order workflow (cart check, checkout validation, status progression, inventory increment on delivery).
  7. API session timeouts, concurrency integrity checks.

### Manual Verification
- We will boot the server using `npm run dev` and perform manual curl checks or test suite verification.
