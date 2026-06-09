const express = require('express');
const cors = require('cors');
const errorHandler = require('./middleware/error');

const authRouter = require('./routes/auth');
const groceryRouter = require('./routes/grocery');
const recipeRouter = require('./routes/recipe');
const mealPlanRouter = require('./routes/mealPlan');
const shoppingListRouter = require('./routes/shoppingList');
const orderRouter = require('./routes/order');
const analyticsRouter = require('./routes/analytics');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Routing
app.use('/api/auth', authRouter);
app.use('/api/groceries', groceryRouter);
app.use('/api/recipes', recipeRouter);
app.use('/api/meal-plans', mealPlanRouter);
app.use('/api/shopping-list', shoppingListRouter);
app.use('/api/orders', orderRouter);
app.use('/api/analytics', analyticsRouter);

// Root Status
app.get('/status', (req, res) => {
  res.status(200).json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Global Error Handler
app.use(errorHandler);

module.exports = app;
