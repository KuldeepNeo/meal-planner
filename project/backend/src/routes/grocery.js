const express = require('express');
const router = express.Router();
const { getDatabase } = require('../models/db');
const authMiddleware = require('../middleware/auth');
const { validate, schemas } = require('../middleware/validate');

// Helper to calculate stock status dynamically
function calculateStatus(quantity, threshold, expiryDate) {
  if (quantity === 0) return 'OUT_OF_STOCK';
  
  if (expiryDate) {
    const expiry = new Date(expiryDate);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const diffTime = expiry.getTime() - today.getTime();
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    
    // Expiring within 3 days
    if (diffDays >= 0 && diffDays <= 3) {
      return 'EXPIRING_SOON';
    }
  }

  if (quantity <= threshold) return 'LOW_STOCK';
  return 'IN_STOCK';
}

// GET /api/groceries
router.get('/', authMiddleware, async (req, res, next) => {
  try {
    const db = await getDatabase();
    
    // Fetch all user items
    const items = await db.all('SELECT * FROM GroceryItem WHERE user_id = ?', [req.user.id]);
    
    // Recalculate and update status if dates changed, keeping the DB in sync
    const now = new Date().toISOString();
    await db.exec('BEGIN TRANSACTION;');
    try {
      for (const item of items) {
        const currentStatus = calculateStatus(item.quantity, item.low_stock_threshold, item.expiry_date);
        if (currentStatus !== item.status) {
          await db.run(
            'UPDATE GroceryItem SET status = ?, updated_at = ? WHERE id = ?',
            [currentStatus, now, item.id]
          );
          item.status = currentStatus; // update in-memory object too
        }
      }
      await db.exec('COMMIT;');
    } catch (err) {
      await db.exec('ROLLBACK;');
      throw err;
    }

    // Map to camelCase response format specified in api contract
    const mapped = items.map(item => ({
      id: item.id,
      itemName: item.item_name,
      quantity: item.quantity,
      unit: item.unit,
      expiryDate: item.expiry_date,
      status: item.status
    }));

    return res.status(200).json(mapped);
  } catch (error) {
    next(error);
  }
});

// POST /api/groceries
router.post('/', authMiddleware, validate(schemas.grocery), async (req, res, next) => {
  try {
    const { itemName, quantity, unit, expiryDate, lowStockThreshold } = req.body;
    const db = await getDatabase();
    const now = new Date().toISOString();
    
    const threshold = lowStockThreshold !== undefined ? lowStockThreshold : 1.0;
    const computedStatus = calculateStatus(quantity, threshold, expiryDate);

    await db.exec('BEGIN TRANSACTION;');
    let itemId;
    try {
      const existing = await db.get(
        'SELECT * FROM GroceryItem WHERE user_id = ? AND LOWER(item_name) = LOWER(?)',
        [req.user.id, itemName]
      );

      if (existing) {
        itemId = existing.id;
        const newQuantity = existing.quantity + quantity;
        const newStatus = calculateStatus(newQuantity, existing.low_stock_threshold, expiryDate || existing.expiry_date);
        
        await db.run(
          'UPDATE GroceryItem SET quantity = ?, status = ?, expiry_date = ?, updated_at = ? WHERE id = ?',
          [newQuantity, newStatus, expiryDate || existing.expiry_date, now, itemId]
        );

        // Log InventoryTransaction
        await db.run(
          `INSERT INTO InventoryTransaction (grocery_item_id, transaction_type, quantity_change, reference_type, created_at)
           VALUES (?, ?, ?, ?, ?)`,
          [itemId, 'ADD', quantity, 'MANUAL', now]
        );
      } else {
        const result = await db.run(
          `INSERT INTO GroceryItem (user_id, item_name, quantity, unit, low_stock_threshold, expiry_date, status, created_at, updated_at) 
           VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
          [req.user.id, itemName, quantity, unit, threshold, expiryDate || null, computedStatus, now, now]
        );
        itemId = result.lastID;

        // Log InventoryTransaction
        await db.run(
          `INSERT INTO InventoryTransaction (grocery_item_id, transaction_type, quantity_change, reference_type, created_at)
           VALUES (?, ?, ?, ?, ?)`,
          [itemId, 'ADD', quantity, 'MANUAL', now]
        );
      }

      await db.exec('COMMIT;');
    } catch (err) {
      await db.exec('ROLLBACK;');
      throw err;
    }

    return res.status(201).json({ id: itemId });
  } catch (error) {
    next(error);
  }
});

// PUT /api/groceries/{id}
router.put('/:id', authMiddleware, validate(schemas.groceryUpdate), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { quantity } = req.body; // according to contract: {"quantity": 5}
    const db = await getDatabase();
    
    // Find item
    const item = await db.get('SELECT * FROM GroceryItem WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }

    const newQuantity = quantity !== undefined ? quantity : item.quantity;
    const newStatus = calculateStatus(newQuantity, item.low_stock_threshold, item.expiry_date);
    const now = new Date().toISOString();

    await db.exec('BEGIN TRANSACTION;');
    try {
      await db.run(
        'UPDATE GroceryItem SET quantity = ?, status = ?, updated_at = ? WHERE id = ?',
        [newQuantity, newStatus, now, id]
      );

      // Log transaction if quantity changed
      if (quantity !== undefined && quantity !== item.quantity) {
        const change = quantity - item.quantity;
        await db.run(
          `INSERT INTO InventoryTransaction (grocery_item_id, transaction_type, quantity_change, reference_type, created_at)
           VALUES (?, ?, ?, ?, ?)`,
          [id, change > 0 ? 'ADD' : 'CONSUME', change, 'MANUAL', now]
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

// DELETE /api/groceries/{id}
router.delete('/:id', authMiddleware, async (req, res, next) => {
  try {
    const { id } = req.params;
    const db = await getDatabase();
    
    const item = await db.get('SELECT id FROM GroceryItem WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!item) {
      return res.status(404).json({ error: 'Item not found' });
    }

    await db.run('DELETE FROM GroceryItem WHERE id = ?', [id]);

    return res.status(200).json({ message: 'Deleted' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
