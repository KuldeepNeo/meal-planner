# database-design.md

## 1. Entity List

| Entity               | Purpose                         |
| -------------------- | ------------------------------- |
| User                 | User account and authentication |
| UserSession          | JWT session tracking            |
| PasswordResetToken   | Password reset workflow         |
| GroceryItem          | Inventory management            |
| Recipe               | Recipe master record            |
| RecipeIngredient     | Ingredients required for recipe |
| MealPlan             | Daily/Weekly meal plan          |
| MealPlanItem         | Recipe assignment to meal slots |
| ShoppingList         | Generated shopping list         |
| ShoppingListItem     | Shopping list ingredients       |
| Vendor               | Grocery supplier/vendor         |
| CustomerOrder        | Grocery order                   |
| OrderItem            | Ordered grocery items           |
| OrderTrackingEvent   | Delivery tracking history       |
| UserMetric           | Business KPI measurements       |
| InventoryTransaction | Inventory audit trail           |

---

## 2. Table Definitions

### User

Stores registered users.

### UserSession

Stores active login sessions and refresh tokens.

### PasswordResetToken

Stores password reset requests.

### GroceryItem

Stores inventory items owned by user.

### Recipe

Stores recipes created by users.

### RecipeIngredient

Stores ingredients associated with recipes.

### MealPlan

Stores meal planning schedules.

### MealPlanItem

Stores meal slot assignments.

### ShoppingList

Stores generated shopping lists.

### ShoppingListItem

Stores shopping list entries.

### Vendor

Stores grocery vendors.

### CustomerOrder

Stores grocery orders.

### OrderItem

Stores ordered products.

### OrderTrackingEvent

Stores delivery tracking events.

### InventoryTransaction

Stores inventory increases and decreases.

### UserMetric

Stores business KPI calculation data.

---

## 3. Column Definitions

### User

| Column        | Type     | Constraints     |
| ------------- | -------- | --------------- |
| id            | INTEGER  | PK              |
| name          | TEXT     | NOT NULL        |
| email         | TEXT     | NOT NULL UNIQUE |
| password_hash | TEXT     | NOT NULL        |
| status        | TEXT     | NOT NULL        |
| created_at    | DATETIME | NOT NULL        |
| updated_at    | DATETIME | NOT NULL        |

---

### UserSession

| Column        | Type     | Constraints |
| ------------- | -------- | ----------- |
| id            | INTEGER  | PK          |
| user_id       | INTEGER  | FK          |
| jwt_token     | TEXT     | NOT NULL    |
| refresh_token | TEXT     | NOT NULL    |
| expires_at    | DATETIME | NOT NULL    |
| created_at    | DATETIME | NOT NULL    |

---

### PasswordResetToken

| Column     | Type     | Constraints |
| ---------- | -------- | ----------- |
| id         | INTEGER  | PK          |
| user_id    | INTEGER  | FK          |
| token      | TEXT     | UNIQUE      |
| expires_at | DATETIME | NOT NULL    |
| used_at    | DATETIME | NULL        |

---

### GroceryItem

| Column              | Type     | Constraints |
| ------------------- | -------- | ----------- |
| id                  | INTEGER  | PK          |
| user_id             | INTEGER  | FK          |
| item_name           | TEXT     | NOT NULL    |
| quantity            | REAL     | NOT NULL    |
| unit                | TEXT     | NOT NULL    |
| low_stock_threshold | REAL     | NOT NULL    |
| expiry_date         | DATE     | NULL        |
| status              | TEXT     | NOT NULL    |
| created_at          | DATETIME | NOT NULL    |
| updated_at          | DATETIME | NOT NULL    |

---

### Recipe

| Column       | Type     | Constraints |
| ------------ | -------- | ----------- |
| id           | INTEGER  | PK          |
| user_id      | INTEGER  | FK          |
| recipe_name  | TEXT     | NOT NULL    |
| description  | TEXT     | NULL        |
| instructions | TEXT     | NULL        |
| servings     | INTEGER  | NOT NULL    |
| created_at   | DATETIME | NOT NULL    |
| updated_at   | DATETIME | NOT NULL    |

---

### RecipeIngredient

| Column          | Type    | Constraints |
| --------------- | ------- | ----------- |
| id              | INTEGER | PK          |
| recipe_id       | INTEGER | FK          |
| grocery_item_id | INTEGER | FK NULL     |
| ingredient_name | TEXT    | NOT NULL    |
| quantity        | REAL    | NOT NULL    |
| unit            | TEXT    | NOT NULL    |

---

### MealPlan

| Column     | Type     | Constraints |
| ---------- | -------- | ----------- |
| id         | INTEGER  | PK          |
| user_id    | INTEGER  | FK          |
| start_date | DATE     | NOT NULL    |
| end_date   | DATE     | NOT NULL    |
| created_at | DATETIME | NOT NULL    |

---

### MealPlanItem

| Column        | Type    | Constraints |
| ------------- | ------- | ----------- |
| id            | INTEGER | PK          |
| meal_plan_id  | INTEGER | FK          |
| recipe_id     | INTEGER | FK          |
| meal_date     | DATE    | NOT NULL    |
| meal_type     | TEXT    | NOT NULL    |
| serving_count | INTEGER | NOT NULL    |

---

### ShoppingList

| Column       | Type     | Constraints |
| ------------ | -------- | ----------- |
| id           | INTEGER  | PK          |
| user_id      | INTEGER  | FK          |
| meal_plan_id | INTEGER  | FK          |
| generated_at | DATETIME | NOT NULL    |
| status       | TEXT     | NOT NULL    |

---

### ShoppingListItem

| Column           | Type    | Constraints |
| ---------------- | ------- | ----------- |
| id               | INTEGER | PK          |
| shopping_list_id | INTEGER | FK          |
| ingredient_name  | TEXT    | NOT NULL    |
| quantity         | REAL    | NOT NULL    |
| unit             | TEXT    | NOT NULL    |
| is_custom        | BOOLEAN | NOT NULL    |
| vendor_id        | INTEGER | FK NULL     |

---

### Vendor

| Column      | Type    | Constraints |
| ----------- | ------- | ----------- |
| id          | INTEGER | PK          |
| vendor_name | TEXT    | NOT NULL    |
| status      | TEXT    | NOT NULL    |

---

### CustomerOrder

| Column             | Type          | Constraints |
| ------------------ | ------------- | ----------- |
| id                 | INTEGER       | PK          |
| user_id            | INTEGER       | FK          |
| shopping_list_id   | INTEGER       | FK          |
| order_number       | TEXT          | UNIQUE      |
| total_amount       | DECIMAL(10,2) |             |
| payment_method     | TEXT          | NOT NULL    |
| delivery_address   | TEXT          | NOT NULL    |
| status             | TEXT          | NOT NULL    |
| estimated_delivery | DATETIME      | NULL        |
| created_at         | DATETIME      | NOT NULL    |

---

### OrderItem

| Column          | Type          | Constraints |
| --------------- | ------------- | ----------- |
| id              | INTEGER       | PK          |
| order_id        | INTEGER       | FK          |
| ingredient_name | TEXT          | NOT NULL    |
| quantity        | REAL          | NOT NULL    |
| unit            | TEXT          | NOT NULL    |
| price           | DECIMAL(10,2) |             |

---

### OrderTrackingEvent

| Column     | Type     | Constraints |
| ---------- | -------- | ----------- |
| id         | INTEGER  | PK          |
| order_id   | INTEGER  | FK          |
| status     | TEXT     | NOT NULL    |
| event_time | DATETIME | NOT NULL    |
| notes      | TEXT     | NULL        |

---

### InventoryTransaction

| Column           | Type     | Constraints |
| ---------------- | -------- | ----------- |
| id               | INTEGER  | PK          |
| grocery_item_id  | INTEGER  | FK          |
| transaction_type | TEXT     | NOT NULL    |
| quantity_change  | REAL     | NOT NULL    |
| reference_type   | TEXT     | NOT NULL    |
| reference_id     | INTEGER  | NULL        |
| created_at       | DATETIME | NOT NULL    |

---

### UserMetric

| Column        | Type     | Constraints |
| ------------- | -------- | ----------- |
| id            | INTEGER  | PK          |
| user_id       | INTEGER  | FK          |
| metric_name   | TEXT     | NOT NULL    |
| metric_value  | REAL     | NOT NULL    |
| metric_period | TEXT     | NOT NULL    |
| calculated_at | DATETIME | NOT NULL    |

---

## 4. Constraints

### Unique Constraints

* User.email
* PasswordResetToken.token
* CustomerOrder.order_number

### Check Constraints

#### GroceryItem

* quantity >= 0
* low_stock_threshold >= 0

#### Recipe

* servings > 0

#### MealPlanItem

* serving_count > 0

#### ShoppingListItem

* quantity > 0

#### OrderItem

* quantity > 0
* price >= 0

### Enumerated Values

#### GroceryItem.status

* IN_STOCK
* LOW_STOCK
* OUT_OF_STOCK
* EXPIRING_SOON

#### MealPlanItem.meal_type

* BREAKFAST
* LUNCH
* DINNER
* SNACK

#### CustomerOrder.status

* PENDING
* CONFIRMED
* PACKED
* OUT_FOR_DELIVERY
* DELIVERED
* CANCELLED

---

## 5. Primary Keys

| Table                | PK |
| -------------------- | -- |
| User                 | id |
| UserSession          | id |
| PasswordResetToken   | id |
| GroceryItem          | id |
| Recipe               | id |
| RecipeIngredient     | id |
| MealPlan             | id |
| MealPlanItem         | id |
| ShoppingList         | id |
| ShoppingListItem     | id |
| Vendor               | id |
| CustomerOrder        | id |
| OrderItem            | id |
| OrderTrackingEvent   | id |
| InventoryTransaction | id |
| UserMetric           | id |

---

## 6. Foreign Keys

| Child Table          | Foreign Key      | Parent Table  |
| -------------------- | ---------------- | ------------- |
| UserSession          | user_id          | User          |
| PasswordResetToken   | user_id          | User          |
| GroceryItem          | user_id          | User          |
| Recipe               | user_id          | User          |
| RecipeIngredient     | recipe_id        | Recipe        |
| RecipeIngredient     | grocery_item_id  | GroceryItem   |
| MealPlan             | user_id          | User          |
| MealPlanItem         | meal_plan_id     | MealPlan      |
| MealPlanItem         | recipe_id        | Recipe        |
| ShoppingList         | user_id          | User          |
| ShoppingList         | meal_plan_id     | MealPlan      |
| ShoppingListItem     | shopping_list_id | ShoppingList  |
| ShoppingListItem     | vendor_id        | Vendor        |
| CustomerOrder        | user_id          | User          |
| CustomerOrder        | shopping_list_id | ShoppingList  |
| OrderItem            | order_id         | CustomerOrder |
| OrderTrackingEvent   | order_id         | CustomerOrder |
| InventoryTransaction | grocery_item_id  | GroceryItem   |
| UserMetric           | user_id          | User          |

---

## 7. Index Strategy

### Authentication

* User(email)
* UserSession(user_id)
* UserSession(expires_at)

### Inventory

* GroceryItem(user_id)
* GroceryItem(status)
* GroceryItem(expiry_date)

### Recipes

* Recipe(user_id)
* RecipeIngredient(recipe_id)

### Meal Planning

* MealPlan(user_id)
* MealPlan(start_date)
* MealPlanItem(meal_date)

### Shopping

* ShoppingList(user_id)
* ShoppingListItem(shopping_list_id)

### Orders

* CustomerOrder(user_id)
* CustomerOrder(status)
* CustomerOrder(created_at)
* OrderTrackingEvent(order_id)

### Analytics

* UserMetric(metric_name)
* UserMetric(calculated_at)

---

# Entity Relationship Diagram

```text
User
 ├── UserSession
 ├── PasswordResetToken
 ├── GroceryItem
 │     └── InventoryTransaction
 ├── Recipe
 │     └── RecipeIngredient
 ├── MealPlan
 │     └── MealPlanItem
 │             └── Recipe
 ├── ShoppingList
 │     └── ShoppingListItem
 │             └── Vendor
 ├── CustomerOrder
 │     ├── OrderItem
 │     └── OrderTrackingEvent
 └── UserMetric

MealPlan
 └── ShoppingList

ShoppingList
 └── CustomerOrder

RecipeIngredient
 └── GroceryItem
```