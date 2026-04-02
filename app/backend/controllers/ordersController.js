const { Pool } = require('pg');
// Assuming pool is configured elsewhere, mocking for this structure
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

const { getIo } = require('../socket'); // Assume a socket module exists
const { sendPushNotification } = require('../services/fcmService'); // Assume FCM service exists

const DELIVERY_FEE = 29.00; // Flat fee MVP

exports.createOrder = async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { user_id, items, delivery_address, payment_method, coupon_code } = req.body;
    
    // Calculate totals and apply mock discounts
    let subtotal = items.reduce((sum, item) => sum + (item.unit_price * item.quantity), 0);
    let discount = coupon_code ? 50.00 : 0.00; // mock discount logic
    let total_amount = subtotal + DELIVERY_FEE - discount;

    const orderQuery = `
      INSERT INTO orders (user_id, total_amount, delivery_fee, discount_amount, coupon_code, status, payment_method, delivery_address)
      VALUES ($1, $2, $3, $4, $5, 'PENDING', $6, $7) RETURNING *;
    `;
    const orderRes = await client.query(orderQuery, [user_id, total_amount, DELIVERY_FEE, discount, coupon_code, payment_method, delivery_address]);
    const order = orderRes.rows[0];

    for (let item of items) {
      const itemQuery = `
        INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, total_price)
        VALUES ($1, $2, $3, $4, $5, $6);
      `;
      await client.query(itemQuery, [order.id, item.product_id, item.product_name, item.quantity, item.unit_price, item.unit_price * item.quantity]);
    }

    await client.query('COMMIT');
    res.status(201).json({ success: true, order });
  } catch (error) {
    await client.query('ROLLBACK');
    res.status(500).json({ success: false, error: error.message });
  } finally {
    client.release();
  }
};

exports.getUserOrders = async (req, res) => {
  try {
    const { userId } = req.params;
    const result = await pool.query('SELECT * FROM orders WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
    res.json({ success: true, orders: result.rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.getOrderById = async (req, res) => {
  try {
    const { orderId } = req.params;
    const orderRes = await pool.query('SELECT * FROM orders WHERE id = $1', [orderId]);
    if (orderRes.rows.length === 0) return res.status(404).json({ success: false, message: 'Order not found' });
    
    const itemsRes = await pool.query('SELECT * FROM order_items WHERE order_id = $1', [orderId]);
    
    res.json({ success: true, order: orderRes.rows[0], items: itemsRes.rows });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.updateOrderStatus = async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const { orderId } = req.params;
    const { status, riderLocation } = req.body;
    
    const currOrder = await client.query('SELECT * FROM orders WHERE id = $1', [orderId]);
    if(currOrder.rows.length === 0) throw new Error('Order not found');
    const oldStatus = currOrder.rows[0].status;

    const updateQuery = 'UPDATE orders SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *';
    const updatedOrder = await client.query(updateQuery, [status, orderId]);

    const logQuery = 'INSERT INTO order_status_logs (order_id, old_status, new_status) VALUES ($1, $2, $3)';
    await client.query(logQuery, [orderId, oldStatus, status]);

    // Deduct stock if confirmed
    if (status === 'CONFIRMED' && oldStatus !== 'CONFIRMED') {
        const items = await client.query('SELECT * FROM order_items WHERE order_id = $1', [orderId]);
        for(let item of items.rows) {
            await client.query('UPDATE products SET stock = stock - $1 WHERE id = $2 AND stock >= $1', [item.quantity, item.product_id]);
        }
    }

    await client.query('COMMIT');
    
    // Socket.io and FCM Events
    const io = getIo();
    if(io) {
      io.to(`order_${orderId}`).emit('order:status_updated', {
          orderId, status, timestamp: new Date(), riderLocation
      });
    }

    await sendPushNotification(currOrder.rows[0].user_id, {
        title: `Order ${status}`,
        body: `Your order status is now ${status}`
    });

    res.json({ success: true, order: updatedOrder.rows[0] });
  } catch (error) {
    await client.query('ROLLBACK');
    res.status(500).json({ success: false, error: error.message });
  } finally {
    client.release();
  }
};
