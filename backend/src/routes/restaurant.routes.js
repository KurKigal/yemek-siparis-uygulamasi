// Restoran verilerinin listelenmesi ve yönetimi için router oluşturulur.
const router = require('express').Router();
const c = require('../controllers/restaurant.controller');
const { authenticate, authorize } = require('../middleware/auth.middleware');

// Tüm kullanıcıların arama yapabileceği ve restoran detaylarını görebileceği açık rotalar.
router.get('/', c.list);
router.get('/:id', c.detail);

// Sisteme yeni bir restoran eklemek için kullanılan, sadece Admin ve Restoran Sahiplerine açık rota.
router.post('/', authenticate, authorize('restaurant_owner', 'admin'), c.create);

// Mevcut bir restoranın bilgilerini güncellemek veya sistemden pasife çekmek (soft delete) için yetkilendirilmiş rotalar.
router.put('/:id', authenticate, authorize('restaurant_owner', 'admin'), c.update);
router.delete('/:id', authenticate, authorize('restaurant_owner', 'admin'), c.remove);

module.exports = router;