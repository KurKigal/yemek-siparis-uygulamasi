// Kullanıcı kimlik doğrulama işlemleri için Express router nesnesi oluşturulur.
const router = require('express').Router();
// İlgili controller fonksiyonları ve JWT doğrulama ara katmanı (middleware) içe aktarılır.
const { register, login, getMe, updateMe, changePassword, updateProfile } = require('../controllers/auth.controller');
const { authenticate } = require('../middleware/auth.middleware');

// Herkese açık olan kayıt olma ve giriş yapma rotaları.
router.post('/register', register);
router.post('/login', login);

// Sisteme giriş yapmış (token sahibi) kullanıcıların erişebileceği korumalı profil rotaları.
router.get('/me', authenticate, getMe);
router.put('/me', authenticate, updateMe);

// Kullanıcının şifresini güvenli bir şekilde değiştirmesini sağlayan rota.
router.post('/change-password', authenticate, changePassword);

// Sadece müşteri rolündeki kullanıcıların isim ve e-posta bilgilerini güncellediği rota.
router.put('/profile', authenticate, updateProfile);

module.exports = router;