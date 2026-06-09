const express = require('express');
const router = express.Router();
const { getDatabase } = require('../models/db');
const authMiddleware = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');

// Helper to get or create active shopping list
async function getOrCreateShoppingList(db, userId) {
  // Find latest meal plan
  let mealPlan = await db.get(
    'SELECT id FROM MealPlan WHERE user_id = ? ORDER BY start_date DESC LIMIT 1',
    [userId]
  );
  
  if (!mealPlan) {
    // Create a dummy meal plan to satisfy the DB foreign key constraint if none exists
    const today = new Date().toISOString().split('T')[0];
    const nextWeek = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
    const res = await db.run(
      'INSERT INTO MealPlan (user_id, start_date, end_date, created_at) VALUES (?, ?, ?, ?)',
      [userId, today, nextWeek, new Date().toISOString()]
    );
    mealPlan = { id: res.lastID };
  }

  // Check if shopping list exists for this meal plan
  let list = await db.get(
    'SELECT id FROM ShoppingList WHERE user_id = ? AND meal_plan_id = ?',
    [userId, mealPlan.id]
  );

  if (!list) {
    const res = await db.run(
      'INSERT INTO ShoppingList (user_id, meal_plan_id, generated_at, status) VALUES (?, ?, ?, ?)',
      [userId, mealPlan.id, new Date().toISOString(), 'DRAFT']
    );
    list = { id: res.lastID };
  }

  return list.id;
}

// GET /api/shopping-list
router.get('/', authMiddleware, async (req, res, next) => {
  try {
    const db = await getDatabase();
    
    // Get or create shopping list
    const listId = await getOrCreateShoppingList(db, req.user.id);

    // Get the shopping list status and meal plan ID
    const list = await db.get('SELECT status, meal_plan_id FROM ShoppingList WHERE id = ?', [listId]);
    const mealPlanId = list.meal_plan_id;

    if (list.status !== 'DRAFT') {
      const dbItems = await db.all(
        'SELECT id, ingredient_name as ingredientName, quantity, unit, is_custom as isCustom FROM ShoppingListItem WHERE shopping_list_id = ?',
        [listId]
      );
      const items = dbItems.map(item => ({
        id: item.id,
        ingredientName: item.ingredientName,
        quantity: item.quantity,
        unit: item.unit,
        isCustom: item.isCustom === 1
      }));
      return res.status(200).json({
        shoppingListId: listId,
        items
      });
    }

    // Fetch all planned meals for this meal plan
    const mealPlanItems = await db.all(
      `SELECT mpi.serving_count, r.servings, ri.ingredient_name, ri.quantity, ri.unit
       FROM MealPlanItem mpi
       JOIN Recipe r ON mpi.recipe_id = r.id
       JOIN RecipeIngredient ri ON ri.recipe_id = r.id
       WHERE mpi.meal_plan_id = ?`,
      [mealPlanId]
    );

    // Aggregate required ingredients by name
    const required = {};
    for (const item of mealPlanItems) {
      const nameLower = item.ingredient_name.toLowerCase();
      const factor = item.serving_count / item.servings;
      const qty = item.quantity * factor;
      
      if (!required[nameLower]) {
        required[nameLower] = {
          name: item.ingredient_name, // keep original casing
          quantity: 0,
          unit: item.unit
        };
      }
      required[nameLower].quantity += qty;
    }

    // Fetch current grocery inventory
    const groceryItems = await db.all(
      'SELECT item_name, quantity FROM GroceryItem WHERE user_id = ?',
      [req.user.id]
    );

    // Aggregate inventory by name
    const inventory = {};
    for (const item of groceryItems) {
      const nameLower = item.item_name.toLowerCase();
      if (!inventory[nameLower]) {
        inventory[nameLower] = 0;
      }
      inventory[nameLower] += item.quantity;
    }

    // Determine missing ingredients (required - inventory)
    const missing = [];
    for (const [nameLower, reqItem] of Object.entries(required)) {
      const avail = inventory[nameLower] || 0;
      if (avail < reqItem.quantity) {
        missing.push({
          name: reqItem.name,
          quantity: reqItem.quantity - avail,
          unit: reqItem.unit
        });
      }
    }

    // Sync database: preserve custom items, overwrite system-generated items
    await db.exec('BEGIN TRANSACTION;');
    try {
      // Delete old auto-generated items
      await db.run('DELETE FROM ShoppingListItem WHERE shopping_list_id = ? AND is_custom = 0', [listId]);

      // Insert new auto-generated items
      for (const item of missing) {
        // Find a random active vendor if available, or set NULL
        const vendor = await db.get('SELECT id FROM Vendor LIMIT 1');
        const vendorId = vendor ? vendor.id : null;

        await db.run(
          `INSERT INTO ShoppingListItem (shopping_list_id, ingredient_name, quantity, unit, is_custom, vendor_id)
           VALUES (?, ?, ?, ?, 0, ?)`,
          [listId, item.name, item.quantity, item.unit, vendorId]
        );
      }
      await db.exec('COMMIT;');
    } catch (err) {
      await db.exec('ROLLBACK;');
      throw err;
    }

    // Fetch and return the consolidated list (auto-generated + custom)
    const dbItems = await db.all(
      'SELECT id, ingredient_name as ingredientName, quantity, unit, is_custom as isCustom FROM ShoppingListItem WHERE shopping_list_id = ?',
      [listId]
    );

    const items = dbItems.map(item => ({
      id: item.id,
      ingredientName: item.ingredientName,
      quantity: item.quantity,
      unit: item.unit,
      isCustom: item.isCustom === 1
    }));

    return res.status(200).json({
      shoppingListId: listId,
      items
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/shopping-list/custom-item
router.post('/custom-item', authMiddleware, validate(schemas.shoppingListCustom), async (req, res, next) => {
  try {
    const { itemName, quantity, unit } = req.body;
    const db = await getDatabase();

    const listId = await getOrCreateShoppingList(db, req.user.id);
    
    // Find vendor if available
    const vendor = await db.get('SELECT id FROM Vendor LIMIT 1');
    const vendorId = vendor ? vendor.id : null;

    const result = await db.run(
      `INSERT INTO ShoppingListItem (shopping_list_id, ingredient_name, quantity, unit, is_custom, vendor_id)
       VALUES (?, ?, ?, ?, 1, ?)`,
      [listId, itemName, quantity, unit, vendorId]
    );

    return res.status(201).json({ id: result.lastID });
  } catch (error) {
    next(error);
  }
});

// PUT /api/shopping-list/items/{id}
router.put('/items/:id', authMiddleware, validate(schemas.shoppingListUpdate), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { quantity } = req.body;
    const db = await getDatabase();

    // Check item ownership via shopping list
    const item = await db.get(
      `SELECT sli.id FROM ShoppingListItem sli
       JOIN ShoppingList sl ON sli.shopping_list_id = sl.id
       WHERE sli.id = ? AND sl.user_id = ?`,
      [id, req.user.id]
    );

    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }

    await db.run(
      'UPDATE ShoppingListItem SET quantity = ? WHERE id = ?',
      [quantity, id]
    );

    return res.status(200).json({ message: 'Updated' });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/shopping-list/items/{id}
router.delete('/items/:id', authMiddleware, async (req, res, next) => {
  try {
    const { id } = req.params;
    const db = await getDatabase();

    // Check item ownership via shopping list
    const item = await db.get(
      `SELECT sli.id FROM ShoppingListItem sli
       JOIN ShoppingList sl ON sli.shopping_list_id = sl.id
       WHERE sli.id = ? AND sl.user_id = ?`,
      [id, req.user.id]
    );

    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }

    await db.run('DELETE FROM ShoppingListItem WHERE id = ?', [id]);

    return res.status(200).json({ message: 'Deleted' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
