# Product Requirements Document (PRD)

# Meal Planner Application

## 1. Problem Statement

Many individuals and families struggle with planning meals, managing grocery inventory, maintaining healthy eating habits, and minimizing food waste. Existing solutions often focus on meal planning, recipe management, or grocery tracking in isolation, creating fragmented user experiences.

Users face several challenges:

* Difficulty planning meals consistently.
* Lack of visibility into available grocery inventory.
* Frequent over-purchasing leading to food waste.
* Time-consuming grocery list preparation.
* Difficulty maintaining dietary goals and healthy eating habits.
* Inefficient grocery ordering workflows.

The Meal Planner Application aims to provide an integrated platform that combines meal planning, recipe management, grocery inventory tracking, shopping list generation, and grocery ordering into a single user experience.

---

# 2. Solution Overview

The Meal Planner Application will allow users to:

* Manage grocery inventory with real-time stock tracking.
* Create and manage recipes with ingredient validation.
* Plan meals daily and weekly through an intuitive planner.
* Automatically identify missing ingredients.
* Generate shopping lists from meal plans.
* Order groceries directly through integrated grocery ordering.
* Track grocery orders after purchase.
* Receive inventory and stock alerts to reduce food waste.

---

# 3. User Flow

## 3.1 User Registration & Authentication

### Registration

1. User opens application.
2. User clicks "Sign Up".
3. User enters:

   * Name
   * Email
   * Password
4. System validates inputs.
5. Account is created.
6. User is redirected to dashboard.

### Login

1. User enters credentials.
2. System validates credentials.
3. JWT session token is generated.
4. User accesses dashboard.

### Password Reset

1. User clicks "Forgot Password".
2. User enters email.
3. System sends reset link.
4. User sets new password.
5. User logs in.

---

## 3.2 Grocery Management Flow

### Add Grocery

1. User navigates to Inventory.
2. User selects "Add Grocery".
3. User enters:

   * Item Name
   * Quantity
   * Unit
   * Expiry Date
4. System saves item.

### Update Grocery

1. User selects item.
2. User edits quantity or details.
3. System updates inventory.

### Delete Grocery

1. User selects grocery item.
2. User confirms deletion.
3. System removes item.

### Inventory Tracking

1. System continuously tracks stock levels.
2. Inventory updates after:

   * Recipe usage
   * Manual updates
   * Grocery purchases

### Stock Status

Inventory statuses:

| Status        | Criteria            |
| ------------- | ------------------- |
| In Stock      | Sufficient quantity |
| Low Stock     | Below threshold     |
| Out of Stock  | Quantity = 0        |
| Expiring Soon | Near expiry date    |

---

## 3.3 Recipe Management Flow

### Create Recipe

1. User clicks "Create Recipe".
2. User enters:

   * Recipe Name
   * Ingredients
   * Preparation Steps
   * Servings
   * Preparation Time
3. System validates ingredients.
4. Recipe is saved.

### Edit Recipe

1. User selects recipe.
2. Updates details.
3. System saves changes.

### Delete Recipe

1. User selects recipe.
2. Confirms deletion.
3. Recipe is removed.

### Ingredient Validation

System verifies:

* Ingredient exists in inventory.
* Required quantity is available.
* Missing ingredients are flagged.

---

## 3.4 Meal Planning Flow

### Weekly Planner

1. User opens weekly planner.
2. User selects dates.
3. User drags recipes into meal slots:

   * Breakfast
   * Lunch
   * Dinner
   * Snacks
4. System saves schedule.

### Daily Planner

1. User selects a date.
2. User chooses recipes.
3. System validates inventory.
4. Meal plan is stored.

### Drag & Drop Scheduling

1. User drags recipe card.
2. Drops into desired meal slot.
3. UI updates instantly.
4. Changes persist automatically.

---

## 3.5 Shopping List Generation Flow

### Missing Ingredient Detection

1. User creates meal plan.
2. System calculates required ingredients.
3. Inventory is checked.
4. Missing ingredients are identified.

### Shopping List Generation

1. Missing items are grouped.
2. Quantities are calculated.
3. Shopping list is generated.
4. User can:

   * Edit list
   * Remove items
   * Add custom items

---

## 3.6 Grocery Ordering Flow

### Add to Cart

1. User opens shopping list.
2. Selects items.
3. Clicks "Order Groceries".
4. Items are added to cart.

### Place Order

1. User reviews cart.
2. Selects delivery address.
3. Chooses payment method.
4. Places order.

### Track Order

1. User opens order history.
2. Selects order.
3. Views:

   * Order status
   * Estimated delivery
   * Delivery updates

Order statuses:

* Pending
* Confirmed
* Packed
* Out for Delivery
* Delivered
* Cancelled

---

# 4. API Design

## Authentication APIs

### POST /api/auth/register

Request:

```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "Password123"
}
```

Response:

```json
{
  "userId": "123",
  "message": "User registered successfully"
}
```

---

### POST /api/auth/login

Request:

```json
{
  "email": "john@example.com",
  "password": "Password123"
}
```

Response:

```json
{
  "token": "jwt-token",
  "refreshToken": "refresh-token"
}
```

---

## Grocery APIs

### GET /api/groceries

Retrieve inventory.

### POST /api/groceries

Create grocery item.

### PUT /api/groceries/{id}

Update grocery item.

### DELETE /api/groceries/{id}

Delete grocery item.

---

## Recipe APIs

### GET /api/recipes

Retrieve recipes.

### POST /api/recipes

Create recipe.

### PUT /api/recipes/{id}

Update recipe.

### DELETE /api/recipes/{id}

Delete recipe.

### POST /api/recipes/validate

Validate recipe ingredients.

---

## Meal Planner APIs

### GET /api/meal-plans

Retrieve meal plans.

### POST /api/meal-plans

Create meal plan.

### PUT /api/meal-plans/{id}

Update meal plan.

### DELETE /api/meal-plans/{id}

Delete meal plan.

---

## Shopping List APIs

### GET /api/shopping-list

Generate shopping list.

### POST /api/shopping-list/custom-item

Add custom item.

---

## Grocery Ordering APIs

### POST /api/orders/cart

Add items to cart.

### POST /api/orders

Create order.

### GET /api/orders

Retrieve orders.

### GET /api/orders/{id}

Retrieve order details.

### GET /api/orders/{id}/tracking

Track order.

---

# 5. Edge Cases

## Authentication

* Duplicate email registration.
* Invalid credentials.
* Expired password reset links.
* Session timeout.
* Multiple concurrent sessions.

---

## Grocery Management

* Negative quantity entered.
* Invalid expiry date.
* Duplicate grocery items.
* Extremely large inventory.

---

## Recipe Management

* Empty ingredient list.
* Missing recipe name.
* Ingredient quantity mismatch.
* Deleted ingredient referenced by recipe.

---

## Meal Planning

* Recipe scheduled multiple times.
* Insufficient inventory for planned meals.
* Drag-and-drop failure.
* Planner synchronization issues.

---

## Shopping List

* Duplicate ingredient aggregation.
* Unit conversion conflicts.
* Ingredient unavailable from vendor.

---

## Grocery Ordering

* Payment failure.
* Inventory unavailable after checkout.
* Delivery address validation failure.
* Partial order fulfillment.
* Order cancellation after dispatch.

---

# 6. KPI (Success Metrics)

| KPI                            | Target |
| ------------------------------ | ------ |
| Weekly Meal Plan Creation Rate | > 70%  |
| Grocery Tracking Usage         | > 80%  |
| Recipe Creation Rate           | > 50%  |
| Grocery Order Conversion Rate  | > 20%  |
| User Retention Rate            | > 60%  |

### Additional Product Metrics

| Metric                                | Goal  |
| ------------------------------------- | ----- |
| Average Meal Plans per User per Month | 4+    |
| Shopping List Generation Rate         | > 75% |
| Inventory Accuracy Rate               | > 90% |
| Order Completion Rate                 | > 95% |
| Food Waste Reduction                  | > 25% |
| Monthly Active Users Growth           | > 10% |

---

# 7. Limitations

## Technical Limitations

* Requires internet connectivity for synchronization.
* Grocery ordering depends on third-party vendor integrations.
* Inventory accuracy relies on user updates.
* Real-time inventory updates may be delayed due to network issues.

## Product Limitations

* No AI-powered meal recommendations in initial release.
* Limited support for complex dietary restrictions in MVP.
* Manual recipe creation required initially.
* Limited grocery vendor availability based on region.

## Operational Limitations

* Order fulfillment controlled by external grocery partners.
* Delivery timelines are dependent on third-party logistics providers.
* Regional pricing and inventory availability may vary.
