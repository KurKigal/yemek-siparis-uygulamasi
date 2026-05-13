// Ödeme simülasyonu için gerekli router ve controller bağlantısı kurulur.
const router = require('express').Router();
const { pay } = require('../controllers/payment.controller');
const { authenticate } = require('../middleware/auth.middleware');

// Belirli bir siparişin ID'sini parametre olarak alıp ödemesini gerçekleştiren ve kimlik doğrulaması gerektiren rota.
router.post('/:orderId', authenticate, pay);

module.exports = router;