const express = require('express');
const router = express.Router();
const ordersController = require('../controllers/ordersController');

// Middleware for authentication would typically go here
// const authMiddleware = require('../middleware/auth');
// router.use(authMiddleware);

// Create order
router.post('/', ordersController.createOrder);

// Fetch order history for a user
router.get('/user/:userId', ordersController.getUserOrders);

// Fetch single order with full details
router.get('/:orderId', ordersController.getOrderById);

// Update order status (admin/rider only)
router.patch('/:orderId/status', ordersController.updateOrderStatus);

module.exports = router;
