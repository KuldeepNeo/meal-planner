const request = require('supertest');
const app = require('../src/app');
const { migrate, getDatabase } = require('../src/models/db');

// Set NODE_ENV to test to trigger in-memory database
process.env.NODE_ENV = 'test';

describe('Meal Planner API Comprehensive Integration Tests', () => {
  let db;
  let authToken;
  let userId;
  let testRecipeId;
  let testMealPlanId;
  let testGroceryId;
  let testShoppingListId;
  let testShoppingListItemId;
  let testOrderId;

  beforeAll(async () => {
    // Migrate schema in in-memory database
    await migrate();
    db = await getDatabase();
    
    // Seed Vendors in the test database
    await db.run("INSERT INTO Vendor (id, vendor_name, status) VALUES (1, 'FreshMart', 'ACTIVE')");
  });

  describe('Module 1: User Registration & Authentication (KPI-AUTH-001 to 011)', () => {
    const userPayload = {
      name: 'John Test',
      email: 'john@test.com',
      password: 'Password123'
    };

    it('should successfully register a new user (KPI-AUTH-001)', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send(userPayload);
      
      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('userId');
      expect(res.body).toHaveProperty('message', 'Registration successful');
      userId = res.body.userId;
    });

    it('should prevent registering a duplicate email (KPI-AUTH-002)', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send(userPayload);
      
      expect(res.status).toBe(409);
      expect(res.body).toHaveProperty('error', 'Email already exists');
    });

    it('should reject registration with missing fields (KPI-AUTH-003)', async () => {
      const res = await request(app)
        .post('/api/auth/register')
        .send({ name: 'John' });
      
      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Validation failed');
    });

    it('should successfully login and return JWT/refresh tokens (KPI-AUTH-004, 006)', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: userPayload.email, password: userPayload.password });
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('token');
      expect(res.body).toHaveProperty('refreshToken');
      expect(res.body).toHaveProperty('userId', userId);
      authToken = res.body.token;
    });

    it('should reject login with invalid credentials (KPI-AUTH-005)', async () => {
      const res = await request(app)
        .post('/api/auth/login')
        .send({ email: userPayload.email, password: 'WrongPassword' });
      
      expect(res.status).toBe(401);
      expect(res.body).toHaveProperty('error', 'Invalid credentials');
    });

    it('should support initiating password reset (KPI-AUTH-007)', async () => {
      const res = await request(app)
        .post('/api/auth/password-reset-request')
        .send({ email: userPayload.email });
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('message', 'Password reset link sent');
    });

    it('should reset password with valid token (KPI-AUTH-008)', async () => {
      // Fetch reset token from DB
      const resetRow = await db.get('SELECT token FROM PasswordResetToken WHERE user_id = ?', [userId]);
      expect(resetRow).toBeDefined();

      const res = await request(app)
        .post('/api/auth/password-reset')
        .send({ token: resetRow.token, newPassword: 'NewPassword123' });
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('message', 'Password updated');

      // Login with new password
      const loginRes = await request(app)
        .post('/api/auth/login')
        .send({ email: userPayload.email, password: 'NewPassword123' });
      
      expect(loginRes.status).toBe(200);
      authToken = loginRes.body.token; // update token
    });
  });

  describe('Module 2: Grocery Inventory Management (KPI-GROC-001 to 016)', () => {
    it('should reject grocery item with negative quantity (KPI-GROC-003)', async () => {
      const res = await request(app)
        .post('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ itemName: 'Apple', quantity: -5, unit: 'Kg' });
      
      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Validation failed');
    });

    it('should reject grocery item with past expiry date (KPI-GROC-004)', async () => {
      const res = await request(app)
        .post('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ itemName: 'Apple', quantity: 2, unit: 'Kg', expiryDate: '2000-01-01' });
      
      expect(res.status).toBe(400);
      expect(res.body).toHaveProperty('error', 'Validation failed');
    });

    it('should add grocery item with valid details (KPI-GROC-001, 011)', async () => {
      // Expiry date far in the future
      const expiry = new Date(Date.now() + 10 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
      const res = await request(app)
        .post('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ itemName: 'Tomato', quantity: 10, unit: 'Piece', expiryDate: expiry, lowStockThreshold: 2 });
      
      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      testGroceryId = res.body.id;

      // Verify status is In Stock
      const getRes = await request(app)
        .get('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(getRes.status).toBe(200);
      const added = getRes.body.find(i => i.id === testGroceryId);
      expect(added).toBeDefined();
      expect(added.status).toBe('IN_STOCK');
    });

    it('should correctly transition to Low Stock (KPI-GROC-012)', async () => {
      // Update quantity to 2 (which is <= lowStockThreshold of 2)
      await request(app)
        .put(`/api/groceries/${testGroceryId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ quantity: 2 });

      const getRes = await request(app)
        .get('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`);
      
      const updated = getRes.body.find(i => i.id === testGroceryId);
      expect(updated.status).toBe('LOW_STOCK');
    });

    it('should correctly transition to Out of Stock (KPI-GROC-013)', async () => {
      // Update quantity to 0
      await request(app)
        .put(`/api/groceries/${testGroceryId}`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ quantity: 0 });

      const getRes = await request(app)
        .get('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`);
      
      const updated = getRes.body.find(i => i.id === testGroceryId);
      expect(updated.status).toBe('OUT_OF_STOCK');
    });

    it('should correctly transition to Expiring Soon (KPI-GROC-014)', async () => {
      // Set expiry to 2 days from now, quantity to 5
      const expiringSoonDate = new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
      
      // We insert directly or update. Since PUT only updates quantity in contract, we can recreate the item.
      const res = await request(app)
        .post('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ itemName: 'Milk', quantity: 5, unit: 'Liter', expiryDate: expiringSoonDate, lowStockThreshold: 1 });
      
      expect(res.status).toBe(201);
      
      const getRes = await request(app)
        .get('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`);
      
      const milkItem = getRes.body.find(i => i.id === res.body.id);
      expect(milkItem.status).toBe('EXPIRING_SOON');
    });
  });

  describe('Module 3: Recipe Management (KPI-RECIPE-001 to 013)', () => {
    it('should create recipe with ingredients (KPI-RECIPE-001)', async () => {
      const recipePayload = {
        recipeName: 'Tomato Pasta',
        servings: 2,
        ingredients: [
          { ingredientName: 'Tomato', quantity: 4, unit: 'Piece' },
          { ingredientName: 'Pasta', quantity: 200, unit: 'Gram' }
        ]
      };

      const res = await request(app)
        .post('/api/recipes')
        .set('Authorization', `Bearer ${authToken}`)
        .send(recipePayload);
      
      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      testRecipeId = res.body.id;
    });

    it('should validate recipe against current inventory and find missing items (KPI-RECIPE-007, 009)', async () => {
      const res = await request(app)
        .post('/api/recipes/validate')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ recipeId: testRecipeId });
      
      expect(res.status).toBe(200);
      expect(res.body.valid).toBe(false);
      // Both Tomato (available 0) and Pasta (available 0) are missing
      expect(res.body.missingIngredients).toContain('Tomato');
      expect(res.body.missingIngredients).toContain('Pasta');
    });

    it('should decrease inventory and log transaction on recipe consumption (KPI-GROC-009)', async () => {
      // Setup: Add enough inventory first
      const tRes = await request(app)
        .post('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ itemName: 'Tomato', quantity: 10, unit: 'Piece', lowStockThreshold: 1 });
      const pRes = await request(app)
        .post('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ itemName: 'Pasta', quantity: 500, unit: 'Gram', lowStockThreshold: 1 });

      // Consume recipe (servings: 2)
      const consumeRes = await request(app)
        .post(`/api/recipes/${testRecipeId}/consume`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ servings: 2 });
      
      expect(consumeRes.status).toBe(200);

      // Verify inventory decreased: Tomato (10 - 4 = 6), Pasta (500 - 200 = 300)
      const getRes = await request(app)
        .get('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`);
      
      const tomato = getRes.body.find(i => i.id === tRes.body.id);
      const pasta = getRes.body.find(i => i.id === pRes.body.id);

      expect(tomato.quantity).toBe(6);
      expect(pasta.quantity).toBe(300);

      // Check transaction logs
      const tx = await db.get(
        'SELECT * FROM InventoryTransaction WHERE grocery_item_id = ? AND transaction_type = "CONSUME" ORDER BY id DESC',
        [tomato.id]
      );
      expect(tx).toBeDefined();
      expect(tx.quantity_change).toBe(-4);
    });
  });

  describe('Module 4: Meal Planning (KPI-MEAL-001 to 015)', () => {
    it('should create weekly meal plan (KPI-MEAL-002)', async () => {
      const res = await request(app)
        .post('/api/meal-plans')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ startDate: '2026-06-09', endDate: '2026-06-15' });
      
      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      testMealPlanId = res.body.id;
    });

    it('should warn when scheduling recipe with insufficient inventory (KPI-MEAL-008)', async () => {
      // Recipe requires 4 Tomatoes and 200g Pasta.
      // Current inventory: 6 Tomatoes and 300g Pasta.
      // Scheduling a slot for 4 servings needs: 4 * (4/2) = 8 Tomatoes, 200 * (4/2) = 400g Pasta.
      // This exceeds available inventory (6 and 300).
      const res = await request(app)
        .post(`/api/meal-plans/${testMealPlanId}/items`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ mealDate: '2026-06-10', mealType: 'DINNER', recipeId: testRecipeId, servingCount: 4 });
      
      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      expect(res.body).toHaveProperty('warning');
      expect(res.body.warning).toContain('Tomato');
      expect(res.body.warning).toContain('Pasta');
    });
  });

  describe('Module 5: Shopping List Management (KPI-SHOP-001 to 011)', () => {
    it('should generate shopping list from meal plans considering inventory (KPI-SHOP-001, 003, 005)', async () => {
      // Required: Tomato (8 Piece), Pasta (400 Gram)
      // Inventory: Tomato (6 Piece), Pasta (300 Gram)
      // Missing: Tomato (2 Piece), Pasta (100 Gram)
      const res = await request(app)
        .get('/api/shopping-list')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('shoppingListId');
      testShoppingListId = res.body.shoppingListId;
      
      const tomatoItem = res.body.items.find(i => i.ingredientName === 'Tomato');
      const pastaItem = res.body.items.find(i => i.ingredientName === 'Pasta');

      expect(tomatoItem).toBeDefined();
      expect(tomatoItem.quantity).toBe(2);
      expect(pastaItem).toBeDefined();
      expect(pastaItem.quantity).toBe(100);
    });

    it('should allow adding custom item to shopping list (KPI-SHOP-009)', async () => {
      const res = await request(app)
        .post('/api/shopping-list/custom-item')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ itemName: 'Bread', quantity: 2, unit: 'Pack' });
      
      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('id');
      testShoppingListItemId = res.body.id;

      // Verify custom item appears on shopping list
      const getList = await request(app)
        .get('/api/shopping-list')
        .set('Authorization', `Bearer ${authToken}`);
      
      const bread = getList.body.items.find(i => i.isCustom === true);
      expect(bread).toBeDefined();
      expect(bread.ingredientName).toBe('Bread');
    });
  });

  describe('Module 6: Grocery Ordering (KPI-ORDER-001 to 021)', () => {
    it('should add shopping list items to cart (KPI-ORDER-001)', async () => {
      const res = await request(app)
        .post('/api/orders/cart')
        .set('Authorization', `Bearer ${authToken}`)
        .send({ shoppingListItemIds: [testShoppingListItemId] });
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('cartId');
    });

    it('should place order and clear shopping list items (KPI-ORDER-003, 006)', async () => {
      const res = await request(app)
        .post('/api/orders')
        .set('Authorization', `Bearer ${authToken}`)
        .send({
          shoppingListId: testShoppingListId,
          deliveryAddress: 'Mumbai Delivery Address',
          paymentMethod: 'CARD'
        });
      
      expect(res.status).toBe(201);
      expect(res.body).toHaveProperty('orderId');
      expect(res.body).toHaveProperty('status', 'PENDING');
      testOrderId = res.body.orderId;

      // Verify list items are cleared
      const getList = await request(app)
        .get('/api/shopping-list')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(getList.body.items.length).toBe(0);
    });

    it('should retrieve order tracking status (KPI-ORDER-009, 020)', async () => {
      const res = await request(app)
        .get(`/api/orders/${testOrderId}/tracking`)
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('status', 'PENDING');
      expect(res.body).toHaveProperty('estimatedDelivery');
      expect(res.body.events.length).toBeGreaterThan(0);
    });

    it('should increase inventory quantities when order transitions to DELIVERED (KPI-GROC-010, KPI-ORDER-014)', async () => {
      // Get current inventory of Tomato and Pasta
      const getGrocBefore = await request(app)
        .get('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`);
      const tomatoBefore = getGrocBefore.body.find(i => i.itemName === 'Tomato');
      const pastaBefore = getGrocBefore.body.find(i => i.itemName === 'Pasta');

      // Update order status to DELIVERED
      const updateRes = await request(app)
        .put(`/api/orders/${testOrderId}/status`)
        .set('Authorization', `Bearer ${authToken}`)
        .send({ status: 'DELIVERED' });
      
      expect(updateRes.status).toBe(200);

      // Verify inventory increased: Tomato (was 6, order was 2, now should be 8)
      // Pasta (was 300, order was 100, now should be 400)
      const getGrocAfter = await request(app)
        .get('/api/groceries')
        .set('Authorization', `Bearer ${authToken}`);
      const tomatoAfter = getGrocAfter.body.find(i => i.itemName === 'Tomato');
      const pastaAfter = getGrocAfter.body.find(i => i.itemName === 'Pasta');

      expect(tomatoAfter.quantity).toBe(tomatoBefore.quantity + 2);
      expect(pastaAfter.quantity).toBe(pastaBefore.quantity + 100);

      // Verify Bread custom item (was not in inventory before) was added
      const bread = getGrocAfter.body.find(i => i.itemName === 'Bread');
      expect(bread).toBeDefined();
      expect(bread.quantity).toBe(2);
    });
  });

  describe('Module 8: Business Success Metrics (KPI-BUS-001 to 011)', () => {
    it('should successfully calculate business metrics rates', async () => {
      const res = await request(app)
        .get('/api/analytics')
        .set('Authorization', `Bearer ${authToken}`);
      
      expect(res.status).toBe(200);
      expect(res.body).toHaveProperty('weeklyMealPlanCreationRate');
      expect(res.body).toHaveProperty('groceryTrackingUsage');
      expect(res.body).toHaveProperty('recipeCreationRate');
      expect(res.body).toHaveProperty('groceryOrderConversionRate');
      expect(res.body).toHaveProperty('userRetentionRate');
      expect(res.body).toHaveProperty('averageMealPlansPerUserPerMonth');
      expect(res.body).toHaveProperty('shoppingListGenerationRate');
    });
  });
});
