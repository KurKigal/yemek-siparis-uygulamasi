// Sipariş operasyonları için Express router ve yetkilendirme katmanları tanımlanır.
const router = require('express').Router();
const c = require('../controllers/order.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');

// Sisteme giriş yapmış her kullanıcının yeni bir sipariş oluşturabileceği rota.
router.post('/', authenticate, c.create);

// Kullanıcının sadece kendi verdiği geçmiş siparişleri listeleyebileceği rota.
router.get('/', authenticate, c.listMine);

// Restoran sahibinin panelinde sadece kendi dükkanına düşen siparişleri görüntüleyebileceği yetkilendirilmiş rota.
router.get('/owner', authenticate, authorize('restaurant_owner'), c.getRestaurantOrders);

// Belirli bir siparişin içeriğini ve ürün detaylarını getiren rota.
router.get('/:id', authenticate, c.detail);

// Siparişin anlık durumunu (hazırlanıyor, yolda vb.) değiştirmek için Admin ve Restoran Sahibine özel rota.
router.put('/:id/status', authenticate, authorize('admin', 'restaurant_owner'), c.updateStatus);

module.exports = router;