const express = require('express');
const router = express.Router();
const { getDatabase } = require('../models/db');
const authMiddleware = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');

// GET /api/meal-plans
router.get('/', authMiddleware, async (req, res, next) => {
  try {
    const db = await getDatabase();
    const plans = await db.all('SELECT * FROM MealPlan WHERE user_id = ?', [req.user.id]);
    
    const mapped = plans.map(p => ({
      id: p.id,
      startDate: p.start_date,
      endDate: p.end_date
    }));

    return res.status(200).json(mapped);
  } catch (error) {
    next(error);
  }
});

// GET /api/meal-plans/{id}
router.get('/:id', authMiddleware, async (req, res, next) => {
  try {
    const { id } = req.params;
    const db = await getDatabase();

    const plan = await db.get('SELECT * FROM MealPlan WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!plan) {
      return res.status(404).json({ error: 'Meal plan not found' });
    }

    const items = await db.all(
      `SELECT mpi.id, mpi.meal_date as mealDate, mpi.meal_type as mealType, 
              mpi.recipe_id as recipeId, mpi.serving_count as servingCount, r.recipe_name as recipeName
       FROM MealPlanItem mpi
       JOIN Recipe r ON mpi.recipe_id = r.id
       WHERE mpi.meal_plan_id = ?`,
      [id]
    );

    return res.status(200).json({
      id: plan.id,
      startDate: plan.start_date,
      endDate: plan.end_date,
      items
    });
  } catch (error) {
    next(error);
  }
});

// POST /api/meal-plans
router.post('/', authMiddleware, validate(schemas.mealPlan), async (req, res, next) => {
  try {
    const { startDate, endDate } = req.body;
    const db = await getDatabase();
    const now = new Date().toISOString();

    const result = await db.run(
      'INSERT INTO MealPlan (user_id, start_date, end_date, created_at) VALUES (?, ?, ?, ?)',
      [req.user.id, startDate, endDate, now]
    );

    return res.status(201).json({ id: result.lastID });
  } catch (error) {
    next(error);
  }
});

// POST /api/meal-plans/{id}/items
router.post('/:id/items', authMiddleware, validate(schemas.mealPlanItem), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { mealDate, mealType, recipeId, servingCount } = req.body;
    const db = await getDatabase();

    // Check plan ownership
    const plan = await db.get('SELECT id FROM MealPlan WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!plan) {
      return res.status(404).json({ error: 'Meal plan not found' });
    }

    // Check recipe ownership & servings
    const recipe = await db.get('SELECT * FROM Recipe WHERE id = ? AND user_id = ?', [recipeId, req.user.id]);
    if (!recipe) {
      return res.status(404).json({ error: 'Recipe not found' });
    }

    const finalServings = servingCount || recipe.servings;

    // Check inventory availability during meal planning (KPI-MEAL-007 / KPI-MEAL-008)
    const ingredients = await db.all('SELECT * FROM RecipeIngredient WHERE recipe_id = ?', [recipeId]);
    const ratio = finalServings / recipe.servings;
    const missing = [];

    for (const ing of ingredients) {
      const invItem = await db.get(
        'SELECT quantity FROM GroceryItem WHERE user_id = ? AND LOWER(item_name) = LOWER(?)',
        [req.user.id, ing.ingredient_name]
      );

      const required = ing.quantity * ratio;
      if (!invItem || invItem.quantity < required) {
        missing.push(ing.ingredient_name);
      }
    }

    let warning = null;
    if (missing.length > 0) {
      warning = `Warning: Insufficient inventory for ingredients: ${missing.join(', ')}`;
    }

    const result = await db.run(
      `INSERT INTO MealPlanItem (meal_plan_id, recipe_id, meal_date, meal_type, serving_count)
       VALUES (?, ?, ?, ?, ?)`,
      [id, recipeId, mealDate, mealType, finalServings]
    );

    const responseBody = { id: result.lastID };
    if (warning) {
      responseBody.warning = warning;
    }

    return res.status(201).json(responseBody);
  } catch (error) {
    next(error);
  }
});

// PUT /api/meal-plans/{id}
router.put('/:id', authMiddleware, validate(schemas.mealPlan), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { startDate, endDate } = req.body;
    const db = await getDatabase();

    const plan = await db.get('SELECT id FROM MealPlan WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!plan) {
      return res.status(404).json({ error: 'Meal plan not found' });
    }

    await db.run(
      'UPDATE MealPlan SET start_date = ?, end_date = ? WHERE id = ?',
      [startDate, endDate, id]
    );

    return res.status(200).json({ message: 'Updated' });
  } catch (error) {
    next(error);
  }
});

// DELETE /api/meal-plans/{id}
router.delete('/:id', authMiddleware, async (req, res, next) => {
  try {
    const { id } = req.params;
    const db = await getDatabase();

    const plan = await db.get('SELECT id FROM MealPlan WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!plan) {
      return res.status(404).json({ error: 'Meal plan not found' });
    }

    await db.run('DELETE FROM MealPlan WHERE id = ?', [id]);

    return res.status(200).json({ message: 'Deleted' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
