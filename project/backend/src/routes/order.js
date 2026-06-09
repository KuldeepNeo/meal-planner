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
    
    if (diffDays >= 0 && diffDays <= 3) {
      return 'EXPIRING_SOON';
    }
  }

  if (quantity <= threshold) return 'LOW_STOCK';
  return 'IN_STOCK';
}

// POST /api/orders/cart
router.post('/cart', authMiddleware, validate(schemas.orderCart), async (req, res, next) => {
  try {
    const { shoppingListItemIds } = req.body;
    const db = await getDatabase();

    // Verify at least one item belongs to user
    const placeholders = shoppingListItemIds.map(() => '?').join(',');
    const check = await db.get(
      `SELECT sli.id FROM ShoppingListItem sli
       JOIN ShoppingList sl ON sli.shopping_list_id = sl.id
       WHERE sli.id IN (${placeholders}) AND sl.user_id = ?`,
      [...shoppingListItemIds, req.user.id]
    );

    if (!check) {
      return res.status(400).json({ error: 'None of the selected items belong to your shopping list' });
    }

    // Return dummy/cache cartId
    return res.status(200).json({ cartId: 1 });
  } catch (error) {
    next(error);
  }
});

// POST /api/orders
router.post('/', authMiddleware, validate(schemas.orderCreate), async (req, res, next) => {
  try {
    const { shoppingListId, deliveryAddress, paymentMethod } = req.body;
    const db = await getDatabase();

    // Verify shopping list ownership
    const list = await db.get('SELECT * FROM ShoppingList WHERE id = ? AND user_id = ?', [shoppingListId, req.user.id]);
    if (!list) {
      return res.status(404).json({ error: 'Shopping list not found' });
    }

    const listItems = await db.all('SELECT * FROM ShoppingListItem WHERE shopping_list_id = ?', [shoppingListId]);
    if (listItems.length === 0) {
      return res.status(400).json({ error: 'Shopping list is empty' });
    }

    // Generate unique order number
    const orderNumber = 'ORD-' + Date.now() + '-' + Math.floor(Math.random() * 1000);
    // Assign price of 5.00 for simulation
    const itemPrice = 5.00;
    const totalAmount = listItems.length * itemPrice;
    
    const now = new Date().toISOString();
    const estDelivery = new Date(Date.now() + 2 * 60 * 60 * 1000).toISOString(); // 2 hours from now

    await db.exec('BEGIN TRANSACTION;');
    let orderId;
    try {
      const result = await db.run(
        `INSERT INTO CustomerOrder (user_id, shopping_list_id, order_number, total_amount, payment_method, delivery_address, status, estimated_delivery, created_at)
         VALUES (?, ?, ?, ?, ?, ?, 'PENDING', ?, ?)`,
        [req.user.id, shoppingListId, orderNumber, totalAmount, paymentMethod, deliveryAddress, estDelivery, now]
      );
      orderId = result.lastID;

      // Copy shopping list items into order items
      for (const item of listItems) {
        await db.run(
          `INSERT INTO OrderItem (order_id, ingredient_name, quantity, unit, price)
           VALUES (?, ?, ?, ?, ?)`,
          [orderId, item.ingredient_name, item.quantity, item.unit, itemPrice]
        );
      }

      // Record first tracking event
      await db.run(
        `INSERT INTO OrderTrackingEvent (order_id, status, event_time, notes)
         VALUES (?, 'PENDING', ?, 'Order successfully placed')`,
        [orderId, now]
      );

      // Complete order creation, clear shopping list items (simulating purchase flow)
      await db.run('DELETE FROM ShoppingListItem WHERE shopping_list_id = ?', [shoppingListId]);
      await db.run('UPDATE ShoppingList SET status = ? WHERE id = ?', ['ORDERED', shoppingListId]);

      await db.exec('COMMIT;');
    } catch (err) {
      await db.exec('ROLLBACK;');
      throw err;
    }

    return res.status(201).json({
      orderId,
      status: 'PENDING'
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/orders
router.get('/', authMiddleware, async (req, res, next) => {
  try {
    const db = await getDatabase();
    const orders = await db.all('SELECT * FROM CustomerOrder WHERE user_id = ? ORDER BY created_at DESC', [req.user.id]);
    
    const mapped = orders.map(o => ({
      id: o.id,
      orderNumber: o.order_number,
      totalAmount: o.total_amount,
      status: o.status,
      deliveryAddress: o.delivery_address,
      paymentMethod: o.payment_method,
      estimatedDelivery: o.estimated_delivery,
      createdAt: o.created_at
    }));

    return res.status(200).json(mapped);
  } catch (error) {
    next(error);
  }
});

// GET /api/orders/{id}
router.get('/:id', authMiddleware, async (req, res, next) => {
  try {
    const { id } = req.params;
    const db = await getDatabase();

    const order = await db.get('SELECT * FROM CustomerOrder WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const items = await db.all(
      'SELECT id, ingredient_name as ingredientName, quantity, unit, price FROM OrderItem WHERE order_id = ?',
      [id]
    );

    return res.status(200).json({
      id: order.id,
      orderNumber: order.order_number,
      totalAmount: order.total_amount,
      status: order.status,
      deliveryAddress: order.delivery_address,
      paymentMethod: order.payment_method,
      estimatedDelivery: order.estimated_delivery,
      createdAt: order.created_at,
      items
    });
  } catch (error) {
    next(error);
  }
});

// GET /api/orders/{id}/tracking
router.get('/:id/tracking', authMiddleware, async (req, res, next) => {
  try {
    const { id } = req.params;
    const db = await getDatabase();

    const order = await db.get('SELECT * FROM CustomerOrder WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const events = await db.all(
      'SELECT status, event_time as time, notes FROM OrderTrackingEvent WHERE order_id = ? ORDER BY event_time DESC',
      [id]
    );

    return res.status(200).json({
      orderId: order.id,
      status: order.status,
      estimatedDelivery: order.estimated_delivery,
      events
    });
  } catch (error) {
    next(error);
  }
});

// CUSTOM PUT /api/orders/{id}/status (Simulate order tracking lifecycle updates & inventory additions on DELIVERED)
router.put('/:id/status', authMiddleware, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status } = req.body;
    
    if (!status || !['PENDING', 'CONFIRMED', 'PACKED', 'OUT_FOR_DELIVERY', 'DELIVERED', 'CANCELLED'].includes(status)) {
      return res.status(400).json({ error: 'Invalid status' });
    }

    const db = await getDatabase();

    // Check ownership
    const order = await db.get('SELECT * FROM CustomerOrder WHERE id = ? AND user_id = ?', [id, req.user.id]);
    if (!order) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const now = new Date().toISOString();

    await db.exec('BEGIN TRANSACTION;');
    try {
      // Update order status
      await db.run('UPDATE CustomerOrder SET status = ? WHERE id = ?', [status, id]);

      // Record tracking event
      await db.run(
        `INSERT INTO OrderTrackingEvent (order_id, status, event_time, notes)
         VALUES (?, ?, ?, ?)`,
        [id, status, now, `Order state transitioned to ${status}`]
      );

      // If Delivered, add items to inventory (KPI-GROC-010)
      if (status === 'DELIVERED') {
        const items = await db.all('SELECT * FROM OrderItem WHERE order_id = ?', [id]);
        for (const item of items) {
          // Check if user already has this item in inventory
          const existing = await db.get(
            'SELECT * FROM GroceryItem WHERE user_id = ? AND LOWER(item_name) = LOWER(?)',
            [req.user.id, item.ingredient_name]
          );

          let itemId;
          if (existing) {
            const newQty = existing.quantity + item.quantity;
            const newStatus = calculateStatus(newQty, existing.low_stock_threshold, existing.expiry_date);
            await db.run(
              'UPDATE GroceryItem SET quantity = ?, status = ?, updated_at = ? WHERE id = ?',
              [newQty, newStatus, now, existing.id]
            );
            itemId = existing.id;
          } else {
            // Create a default expiry date (7 days from now)
            const expiry = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0];
            const computedStatus = calculateStatus(item.quantity, 1.0, expiry);
            const result = await db.run(
              `INSERT INTO GroceryItem (user_id, item_name, quantity, unit, low_stock_threshold, expiry_date, status, created_at, updated_at)
               VALUES (?, ?, ?, ?, 1.0, ?, ?, ?, ?)`,
              [req.user.id, item.ingredient_name, item.quantity, item.unit, expiry, computedStatus, now, now]
            );
            itemId = result.lastID;
          }

          // Log transaction
          await db.run(
            `INSERT INTO InventoryTransaction (grocery_item_id, transaction_type, quantity_change, reference_type, reference_id, created_at)
             VALUES (?, 'ADD', ?, 'ORDER', ?, ?)`,
            [itemId, item.quantity, id, now]
          );
        }
      }

      await db.exec('COMMIT;');
    } catch (err) {
      await db.exec('ROLLBACK;');
      throw err;
    }

    return res.status(200).json({ message: 'Status updated' });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
