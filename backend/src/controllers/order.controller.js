const { getDB } = require('../db/database');

/**
 * Müşteriden gelen sepet verisiyle yeni bir sipariş oluşturur.
 * Siparişteki ürünlerin stok durumu kontrol edilir ve herhangi bir hatada
 * tüm işlemlerin geri alınabilmesi için SQLite Transaction kullanılır.
 */
function create(req, res) {
  const { restaurant_id, items, address } = req.body;

  if (!restaurant_id || !items?.length || !address)
    return res.status(400).json({ message: 'Eksik sipariş bilgisi' });

  const db = getDB();
  let total = 0;
  const resolved = [];

  for (const item of items) {
    const menuItem = db.prepare(
      'SELECT * FROM menu_items WHERE id=? AND is_available=1'
    ).get(item.menu_item_id);

    if (!menuItem) return res.status(400).json({ message: `Ürün bulunamadı: ${item.menu_item_id}` });
    if (menuItem.stock < item.quantity) return res.status(400).json({ message: `Yetersiz stok: ${menuItem.name}` });

    total += menuItem.price * item.quantity;
    resolved.push({ ...item, unit_price: menuItem.price });
  }

  const insertOrder = db.transaction(() => {
    const order = db.prepare(
      'INSERT INTO orders (user_id, restaurant_id, total_price, address) VALUES (?,?,?,?)'
    ).run(req.user.id, restaurant_id, total, address);

    for (const item of resolved) {
      db.prepare(
        'INSERT INTO order_items (order_id, menu_item_id, quantity, unit_price) VALUES (?,?,?,?)'
      ).run(order.lastInsertRowid, item.menu_item_id, item.quantity, item.unit_price);

      db.prepare('UPDATE menu_items SET stock = stock - ? WHERE id=?').run(item.quantity, item.menu_item_id);
    }
    return order.lastInsertRowid;
  });

  const orderId = insertOrder();
  res.status(201).json({ id: orderId, total_price: total, status: 'hazirlaniyor' });
}

/**
 * Kullanıcının geçmişte verdiği kendi siparişlerini detaylarıyla birlikte listeler.
 */
function listMine(req, res) {
  const db = getDB();
  const orders = db.prepare(
    `SELECT o.*, r.name as restaurant_name
     FROM orders o
     JOIN restaurants r ON r.id = o.restaurant_id
     WHERE o.user_id=? ORDER BY o.created_at DESC`
  ).all(req.user.id);

  for (const order of orders) {
    order.items = db.prepare(
      `SELECT oi.*, m.name FROM order_items oi
       JOIN menu_items m ON m.id = oi.menu_item_id
       WHERE oi.order_id=?`
    ).all(order.id);
  }
  res.json(orders);
}

/**
 * Restoran sahibinin kendi paneli üzerinden dükkanına gelen siparişleri görmesini sağlar.
 */
function getRestaurantOrders(req, res, next) {
  try {
    const db = getDB();
    const restaurant = db.prepare('SELECT id FROM restaurants WHERE owner_id = ?').get(req.user.id);

    if (!restaurant) {
      return res.status(404).json({ message: 'Size ait bir restoran bulunamadı.' });
    }

    const orders = db.prepare(`
      SELECT o.*, u.name as customer_name
      FROM orders o
      JOIN users u ON o.user_id = u.id
      WHERE o.restaurant_id = ?
      ORDER BY o.created_at DESC
    `).all(restaurant.id);

    res.json(orders);
  } catch (err) {
    next(err);
  }
}

/**
 * İlgili siparişin içeriğini, görsel ve ürün bazlı detaylarıyla getirir.
 */
function detail(req, res) {
  const db = getDB();
  const order = db.prepare('SELECT * FROM orders WHERE id=?').get(req.params.id);
  if (!order) return res.status(404).json({ message: 'Sipariş bulunamadı' });

  if (order.user_id !== req.user.id && req.user.role !== 'admin')
    return res.status(403).json({ message: 'Yetki yok' });

  order.items = db.prepare(
    `SELECT oi.*, m.name, m.image_url FROM order_items oi
     JOIN menu_items m ON m.id = oi.menu_item_id WHERE oi.order_id=?`
  ).all(order.id);
  res.json(order);
}

/**
 * Siparişin anlık operasyonel durumunu (hazırlanıyor, yolda, teslim_edildi) günceller.
 */
function updateStatus(req, res) {
  const { status } = req.body;
  const validStatuses = ['hazirlaniyor', 'yolda', 'teslim_edildi'];
  if (!validStatuses.includes(status))
    return res.status(400).json({ message: 'Geçersiz durum' });

  const db = getDB();

  if (req.user.role === 'restaurant_owner') {
    const check = db.prepare(`
      SELECT o.id FROM orders o
      JOIN restaurants r ON o.restaurant_id = r.id
      WHERE o.id = ? AND r.owner_id = ?
    `).get(req.params.id, req.user.id);

    if (!check) return res.status(403).json({ message: 'Bu siparişi güncelleme yetkiniz yok.' });
  }

  db.prepare('UPDATE orders SET status=? WHERE id=?').run(status, req.params.id);
  res.json({ message: 'Durum güncellendi', status });
}

module.exports = { create, listMine, detail, updateStatus, getRestaurantOrders };