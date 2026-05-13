// Menü işlemleri için gerekli router, controller ve yetkilendirme ara katmanları çağrılır.
const router = require('express').Router();
const c = require('../controllers/menu.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');

// Restoran sahibinin kendi paneli üzerinden sadece kendi dükkanına ait menüyü getiren rota.
// Çakışmaları önlemek adına statik '/owner' rotası, dinamik '/:restaurantId' rotasından önce tanımlanmalıdır.
router.get('/owner', authenticate, authorize('restaurant_owner'), c.getOwnerMenu);

// Restoran sahibinin, kendi dükkanına yeni bir ürün eklemesini sağlayan rota.
router.post('/', authenticate, authorize('restaurant_owner'), c.create);

// Sadece Admin ve ilgili Restoran Sahibinin yetkili olduğu, mevcut ürünü güncelleme ve silme (soft delete) rotaları.
router.put('/:id', authenticate, authorize('restaurant_owner', 'admin'), c.update);
router.delete('/:id', authenticate, authorize('restaurant_owner', 'admin'), c.remove);

// Müşteriler için belirli bir restoranın aktif menü öğelerini listeleyen herkese açık rota.
router.get('/:restaurantId', c.listByRestaurant);

// Belirli bir restoran ID'si belirtilerek o restorana ürün eklenmesini sağlayan alternatif rota.
router.post('/:restaurantId', authenticate, authorize('restaurant_owner', 'admin'), c.create);

// Eski frontend yapıları veya uyumluluk için korunmuş olan ürün güncelleme ve silme alternatif rotaları.
router.put('/item/:id', authenticate, authorize('restaurant_owner', 'admin'), c.update);
router.delete('/item/:id', authenticate, authorize('restaurant_owner', 'admin'), c.remove);

module.exports = router;