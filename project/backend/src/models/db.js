const { getDatabase } = require('../config/database');

async function migrate() {
  const db = await getDatabase();
  
  await db.exec('BEGIN TRANSACTION;');
  try {
    // 1. User
    await db.exec(`
      CREATE TABLE IF NOT EXISTS User (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        status TEXT NOT NULL,
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL
      );
    `);

    // 2. UserSession
    await db.exec(`
      CREATE TABLE IF NOT EXISTS UserSession (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        jwt_token TEXT NOT NULL,
        refresh_token TEXT NOT NULL,
        expires_at DATETIME NOT NULL,
        created_at DATETIME NOT NULL,
        FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE
      );
    `);

    // 3. PasswordResetToken
    await db.exec(`
      CREATE TABLE IF NOT EXISTS PasswordResetToken (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        token TEXT UNIQUE NOT NULL,
        expires_at DATETIME NOT NULL,
        used_at DATETIME NULL,
        FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE
      );
    `);

    // 4. GroceryItem
    await db.exec(`
      CREATE TABLE IF NOT EXISTS GroceryItem (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        item_name TEXT NOT NULL,
        quantity REAL NOT NULL CHECK(quantity >= 0),
        unit TEXT NOT NULL,
        low_stock_threshold REAL NOT NULL CHECK(low_stock_threshold >= 0),
        expiry_date DATE NULL,
        status TEXT NOT NULL CHECK(status IN ('IN_STOCK', 'LOW_STOCK', 'OUT_OF_STOCK', 'EXPIRING_SOON')),
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE
      );
    `);

    // 5. Recipe
    await db.exec(`
      CREATE TABLE IF NOT EXISTS Recipe (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        recipe_name TEXT NOT NULL,
        description TEXT NULL,
        instructions TEXT NULL,
        servings INTEGER NOT NULL CHECK(servings > 0),
        created_at DATETIME NOT NULL,
        updated_at DATETIME NOT NULL,
        FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE
      );
    `);

    // 6. RecipeIngredient
    await db.exec(`
      CREATE TABLE IF NOT EXISTS RecipeIngredient (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        recipe_id INTEGER NOT NULL,
        grocery_item_id INTEGER NULL,
        ingredient_name TEXT NOT NULL,
        quantity REAL NOT NULL CHECK(quantity > 0),
        unit TEXT NOT NULL,
        FOREIGN KEY (recipe_id) REFERENCES Recipe(id) ON DELETE CASCADE,
        FOREIGN KEY (grocery_item_id) REFERENCES GroceryItem(id) ON DELETE SET NULL
      );
    `);

    // 7. MealPlan
    await db.exec(`
      CREATE TABLE IF NOT EXISTS MealPlan (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        start_date DATE NOT NULL,
        end_date DATE NOT NULL,
        created_at DATETIME NOT NULL,
        FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE
      );
    `);

    // 8. MealPlanItem
    await db.exec(`
      CREATE TABLE IF NOT EXISTS MealPlanItem (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        meal_plan_id INTEGER NOT NULL,
        recipe_id INTEGER NOT NULL,
        meal_date DATE NOT NULL,
        meal_type TEXT NOT NULL CHECK(meal_type IN ('BREAKFAST', 'LUNCH', 'DINNER', 'SNACK')),
        serving_count INTEGER NOT NULL CHECK(serving_count > 0),
        FOREIGN KEY (meal_plan_id) REFERENCES MealPlan(id) ON DELETE CASCADE,
        FOREIGN KEY (recipe_id) REFERENCES Recipe(id) ON DELETE CASCADE
      );
    `);

    // 9. ShoppingList
    await db.exec(`
      CREATE TABLE IF NOT EXISTS ShoppingList (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        meal_plan_id INTEGER NOT NULL,
        generated_at DATETIME NOT NULL,
        status TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE,
        FOREIGN KEY (meal_plan_id) REFERENCES MealPlan(id) ON DELETE CASCADE
      );
    `);

    // 10. Vendor
    await db.exec(`
      CREATE TABLE IF NOT EXISTS Vendor (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vendor_name TEXT NOT NULL,
        status TEXT NOT NULL
      );
    `);

    // 11. ShoppingListItem
    await db.exec(`
      CREATE TABLE IF NOT EXISTS ShoppingListItem (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        shopping_list_id INTEGER NOT NULL,
        ingredient_name TEXT NOT NULL,
        quantity REAL NOT NULL CHECK(quantity > 0),
        unit TEXT NOT NULL,
        is_custom BOOLEAN NOT NULL CHECK(is_custom IN (0, 1)),
        vendor_id INTEGER NULL,
        FOREIGN KEY (shopping_list_id) REFERENCES ShoppingList(id) ON DELETE CASCADE,
        FOREIGN KEY (vendor_id) REFERENCES Vendor(id) ON DELETE SET NULL
      );
    `);

    // 12. CustomerOrder
    await db.exec(`
      CREATE TABLE IF NOT EXISTS CustomerOrder (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        shopping_list_id INTEGER NULL,
        order_number TEXT UNIQUE NOT NULL,
        total_amount REAL NOT NULL CHECK(total_amount >= 0),
        payment_method TEXT NOT NULL,
        delivery_address TEXT NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('PENDING', 'CONFIRMED', 'PACKED', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED')),
        estimated_delivery DATETIME NULL,
        created_at DATETIME NOT NULL,
        FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE,
        FOREIGN KEY (shopping_list_id) REFERENCES ShoppingList(id) ON DELETE SET NULL
      );
    `);

    // 13. OrderItem
    await db.exec(`
      CREATE TABLE IF NOT EXISTS OrderItem (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        ingredient_name TEXT NOT NULL,
        quantity REAL NOT NULL CHECK(quantity > 0),
        unit TEXT NOT NULL,
        price REAL NOT NULL CHECK(price >= 0),
        FOREIGN KEY (order_id) REFERENCES CustomerOrder(id) ON DELETE CASCADE
      );
    `);

    // 14. OrderTrackingEvent
    await db.exec(`
      CREATE TABLE IF NOT EXISTS OrderTrackingEvent (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        status TEXT NOT NULL CHECK(status IN ('PENDING', 'CONFIRMED', 'PACKED', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED')),
        event_time DATETIME NOT NULL,
        notes TEXT NULL,
        FOREIGN KEY (order_id) REFERENCES CustomerOrder(id) ON DELETE CASCADE
      );
    `);

    // 15. InventoryTransaction
    await db.exec(`
      CREATE TABLE IF NOT EXISTS InventoryTransaction (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        grocery_item_id INTEGER NOT NULL,
        transaction_type TEXT NOT NULL,
        quantity_change REAL NOT NULL,
        reference_type TEXT NOT NULL,
        reference_id INTEGER NULL,
        created_at DATETIME NOT NULL,
        FOREIGN KEY (grocery_item_id) REFERENCES GroceryItem(id) ON DELETE CASCADE
      );
    `);

    // 16. UserMetric
    await db.exec(`
      CREATE TABLE IF NOT EXISTS UserMetric (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        metric_name TEXT NOT NULL,
        metric_value REAL NOT NULL,
        metric_period TEXT NOT NULL,
        calculated_at DATETIME NOT NULL,
        FOREIGN KEY (user_id) REFERENCES User(id) ON DELETE CASCADE
      );
    `);

    // Indexes
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_usersession_user_id ON UserSession(user_id);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_usersession_expires_at ON UserSession(expires_at);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_groceryitem_user_id ON GroceryItem(user_id);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_groceryitem_status ON GroceryItem(status);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_groceryitem_expiry_date ON GroceryItem(expiry_date);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_recipe_user_id ON Recipe(user_id);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_recipeingredient_recipe_id ON RecipeIngredient(recipe_id);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_mealplan_user_id ON MealPlan(user_id);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_mealplan_start_date ON MealPlan(start_date);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_mealplanitem_meal_date ON MealPlanItem(meal_date);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_shoppinglist_user_id ON ShoppingList(user_id);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_shoppinglistitem_shopping_list_id ON ShoppingListItem(shopping_list_id);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_customerorder_user_id ON CustomerOrder(user_id);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_customerorder_status ON CustomerOrder(status);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_customerorder_created_at ON CustomerOrder(created_at);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_ordertrackingevent_order_id ON OrderTrackingEvent(order_id);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_usermetric_metric_name ON UserMetric(metric_name);`);
    await db.exec(`CREATE INDEX IF NOT EXISTS idx_usermetric_calculated_at ON UserMetric(calculated_at);`);

    await db.exec('COMMIT;');
  } catch (error) {
    await db.exec('ROLLBACK;');
    throw error;
  }
}

module.exports = {
  migrate,
  getDatabase
};
