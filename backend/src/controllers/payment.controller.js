const { getDB } = require('../db/database');

/**
 * Uygulama içi ödeme adımını simüle eden kontrolcüdür.
 * Kullanıcının gönderdiği tutarın, veritabanındaki sipariş tutarı ile eşleşip eşleşmediğini
 * ve limit aşımlarını denetler.
 */
function pay(req, res) {
  const db = getDB();
  const orderId = req.params.orderId;
  const { amount } = req.body;

  const order = db.prepare('SELECT * FROM orders WHERE id=?').get(orderId);
  if (!order) return res.status(404).json({ message: 'Sipariş bulunamadı' });
  if (order.payment_status === 'odendi') return res.status(400).json({ message: 'Bu sipariş zaten ödendi' });

  if (amount < order.total_price) {
    return res.status(400).json({
      success: false,
      message: `Yetersiz miktar! Ödemeniz gereken tutar: ${order.total_price} ₺. Girdiğiniz: ${amount} ₺`
    });
  }

  if (amount > 1000) {
    return res.status(400).json({
      success: false,
      message: 'Güvenlik sınırı: 1000 TL üzeri tek seferlik ödeme reddedildi.'
    });
  }

  db.prepare('UPDATE orders SET payment_status=? WHERE id=?').run('odendi', order.id);

  res.json({
    success: true,
    payment_status: 'odendi',
    message: 'Ödeme başarılı! Afiyet olsun.'
  });
}

module.exports = { pay };