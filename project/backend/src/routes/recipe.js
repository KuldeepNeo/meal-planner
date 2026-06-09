const express = require('express');
const router = express.Router();
const { getDatabase } = require('../models/db');
const authMiddleware = require('../middleware/auth');
const { validate, validateRecipeIngredients, schemas } = require('../middleware/validate');

// Helper to calculate stock status dynamically
function calculateStatus(quantity, threshold, expiryDate) {
  if (quantity === 0) return 'OUT_OF_STOCK';
  
  if (expiryDate) {
    const expiry = new Date(expiryDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const diffTime = expiry.getTime() - today.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays >= 0 && diffDays <= 3) {
      return 'EXPIRING_SOON';
    }
  }

  if (quantity <= threshold) return 'LOW_STOCK';
  return 'IN_STOCK';
}

// GET /api/recipes
router.get('/', authMiddleware, async (req, res, next) => {
  try {
    const db = await getDatabase();
    const recipes = await db.all('SELECT * FROM Recipe WHERE user_id = ?', [req.user.id]);
    
    // Map to API format
    const mapped = recipes.map(r => ({
      id: r.id,
      recipeName: r.recipe_name,
      description: r.description,
      instructions: r.instructions,
      servings: r.servings
    }));

    return res.status(200).json(mapped);
  } catch (error) {
    next(error);
  }
});

// GET /api/recipes/{id}
router.get('/:id', authMiddleware, async (req, res, next) => {
  try {
    const { id } = req.params;
    const db = await getDatabase();

    const recipe = await db.get('SELECT * FROM Recipe WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!recipe) {
      return res.status(404).json({ error: 'Recipe not found' });
    }

    const ingredients = await db.all(
      'SELECT ingredient_name as ingredientName, quantity, unit FROM RecipeIngredient WHERE recipe_id = ?',
      [id]
    );

    return res.status(200).json({
      id: recipe.id,
      recipeName: recipe.recipe_name,
      description: recipe.description,
      instructions: recipe.instructions,
      servings: recipe.servings,
      ingredients
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/recipes
router.post('/', authMiddleware, validate(schemas.recipe), validateRecipeIngredients, async (req, res, next) => {
  try {
    const { recipeName, description, instructions, servings, ingredients } = req.body;
    const db = await getDatabase();
    const now = new Date().toISOString();

    await db.exec('BEGIN TRANSACTION;');
    let recipeId;
    try {
      const result = await db.run(
        'INSERT INTO Recipe (user_id, recipe_name, description, instructions, servings, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [req.user.id, recipeName, description || null, instructions || null, servings, now, now]
      );
      recipeId = result.lastID;

      for (const ing of ingredients) {
        // Find matching grocery item if exists to link foreign key
        const match = await db.get(
          'SELECT id FROM GroceryItem WHERE user_id = ? AND LOWER(item_name) = LOWER(?)',
          [req.user.id, ing.ingredientName]
        );
        const groceryItemId = match ? match.id : null;

        await db.run(
          'INSERT INTO RecipeIngredient (recipe_id, grocery_item_id, ingredient_name, quantity, unit) VALUES (?, ?, ?, ?, ?)',
          [recipeId, groceryItemId, ing.ingredientName, ing.quantity, ing.unit]
        );
      }
      await db.exec('COMMIT;');
    } catch (err) {
      await db.exec('ROLLBACK;');
      throw err;
    }

    return res.status(201).json({ id: recipeId });
  } catch (error) {
    next(error);
  }
});

// PUT /api/recipes/{id}
router.put('/:id', authMiddleware, validate(schemas.recipe), validateRecipeIngredients, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { recipeName, description, instructions, servings, ingredients } = req.body;
    const db = await getDatabase();
    const now = new Date().toISOString();

    const recipe = await db.get('SELECT id FROM Recipe WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!recipe) {
      return res.status(404).json({ error: 'Recipe not found' });
    }

    await db.exec('BEGIN TRANSACTION;');
    try {
      await db.run(
        'UPDATE Recipe SET recipe_name = ?, description = ?, instructions = ?, servings = ?, updated_at = ? WHERE id = ?',
        [recipeName, description || null, instructions || null, servings, now, id]
      );

      // Remove old ingredients
      await db.run('DELETE FROM RecipeIngredient WHERE recipe_id = ?', [id]);

      // Re-insert ingredients
      for (const ing of ingredients) {
        const match = await db.get(
          'SELECT id FROM GroceryItem WHERE user_id = ? AND LOWER(item_name) = LOWER(?)',
          [req.user.id, ing.ingredientName]
        );
        const groceryItemId = match ? match.id : null;

        await db.run(
          'INSERT INTO RecipeIngredient (recipe_id, grocery_item_id, ingredient_name, quantity, unit) VALUES (?, ?, ?, ?, ?)',
          [id, groceryItemId, ing.ingredientName, ing.quantity, ing.unit]
        );
      }

      await db.exec('COMMIT;');
    } catch (err) {
      await db.exec('ROLLBACK;');
      throw err;
    }

    return res.status(200).json({ message: 'Updated' });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/recipes/{id}
router.delete('/:id', authMiddleware, async (req, res, next) => {
  try {
    const { id } = req.params;
    const db = await getDatabase();

    const recipe = await db.get('SELECT id FROM Recipe WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!recipe) {
      return res.status(404).json({ error: 'Recipe not found' });
    }

    await db.run('DELETE FROM Recipe WHERE id = ?', [id]);

    return res.status(200).json({ message: 'Deleted' });
  } catch (error) {
    next(error);
  }
});

// POST /api/recipes/validate
router.post('/validate', authMiddleware, async (req, res, next) => {
  try {
    const { recipeId } = req.body;
    if (!recipeId) {
      return res.status(400).json({ error: 'recipeId is required' });
    }

    const db = await getDatabase();

    // Check recipe
    const recipe = await db.get('SELECT id FROM Recipe WHERE id = ? AND user_id = ?', [recipeId, req.user.id]);
    if (!recipe) {
      return res.status(404).json({ error: 'Recipe not found' });
    }

    const ingredients = await db.all('SELECT * FROM RecipeIngredient WHERE recipe_id = ?', [recipeId]);
    const missingIngredients = [];

    for (const ing of ingredients) {
      const invItem = await db.get(
        'SELECT * FROM GroceryItem WHERE user_id = ? AND LOWER(item_name) = LOWER(?)',
        [req.user.id, ing.ingredient_name]
      );

      if (!invItem || invItem.quantity < ing.quantity) {
        missingIngredients.push(ing.ingredient_name);
      }
    }

    return res.status(200).json({
      valid: missingIngredients.length === 0,
      missingIngredients
    });
  } catch (error) {
    next(error);
  }
});

// CUSTOM POST /api/recipes/{id}/consume (Simulate usage workflow)
router.post('/:id/consume', authMiddleware, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { servings } = req.body;
    const db = await getDatabase();

    const recipe = await db.get('SELECT * FROM Recipe WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!recipe) {
      return res.status(404).json({ error: 'Recipe not found' });
    }

    const ratio = servings ? (servings / recipe.servings) : 1.0;
    const ingredients = await db.all('SELECT * FROM RecipeIngredient WHERE recipe_id = ?', [id]);
    const now = new Date().toISOString();

    await db.exec('BEGIN TRANSACTION;');
    try {
      for (const ing of ingredients) {
        const requiredQty = ing.quantity * ratio;
        const invItem = await db.get(
          'SELECT * FROM GroceryItem WHERE user_id = ? AND LOWER(item_name) = LOWER(?)',
          [req.user.id, ing.ingredient_name]
        );

        if (invItem) {
          const newQty = Math.max(0, invItem.quantity - requiredQty);
          const newStatus = calculateStatus(newQty, invItem.low_stock_threshold, invItem.expiry_date);
          
          await db.run(
            'UPDATE GroceryItem SET quantity = ?, status = ?, updated_at = ? WHERE id = ?',
            [newQty, newStatus, now, invItem.id]
          );

          // Log transaction
          await db.run(
            `INSERT INTO InventoryTransaction (grocery_item_id, transaction_type, quantity_change, reference_type, reference_id, created_at)
             VALUES (?, ?, ?, ?, ?, ?)`,
            [invItem.id, 'CONSUME', -requiredQty, 'RECIPE', id, now]
          );
        }
      }
      await db.exec('COMMIT;');
    } catch (err) {
      await db.exec('ROLLBACK;');
      throw err;
    }

    return res.status(200).json({ message: 'Recipe consumed, inventory updated' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
