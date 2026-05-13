const { getDB } = require('../db/database');

/**
 * Belirli bir restorana ait aktif menü öğelerini müşteriler için listeler.
 */
function listByRestaurant(req, res) {
  const db = getDB();
  const items = db.prepare(
    'SELECT * FROM menu_items WHERE restaurant_id=? AND is_available=1'
  ).all(req.params.restaurantId);
  res.json(items);
}

/**
 * Restoran sahibinin kendi paneli için dükkanındaki tüm aktif ürünleri getirir.
 */
function getOwnerMenu(req, res, next) {
  try {
    const db = getDB();
    const restaurant = db.prepare('SELECT id FROM restaurants WHERE owner_id = ?').get(req.user.id);
    if (!restaurant) return res.status(404).json({ message: 'Restoranınız bulunamadı.' });

    const menu = db.prepare('SELECT * FROM menu_items WHERE restaurant_id = ? AND is_available=1 ORDER BY id DESC').all(restaurant.id);
    res.json(menu);
  } catch (err) {
    next(err);
  }
}

/**
 * Restorana yeni bir ürün ekler.
 * Endpoint'te ID belirtilmemişse işlemi yapan kullanıcının restoranını bularak oraya ekler.
 */
function create(req, res) {
  const { name, description, price, image_url, stock } = req.body;
  if (!name || !price) return res.status(400).json({ message: 'Ad ve fiyat zorunludur' });

  const db = getDB();
  let restId = req.params.restaurantId;

  if (!restId) {
    const restaurant = db.prepare('SELECT id FROM restaurants WHERE owner_id = ?').get(req.user.id);
    if (!restaurant) return res.status(404).json({ message: 'Restoranınız bulunamadı.' });
    restId = restaurant.id;
  } else {
    const restaurant = db.prepare('SELECT owner_id FROM restaurants WHERE id=?').get(restId);
    if (!restaurant) return res.status(404).json({ message: 'Restoran bulunamadı' });
    if (restaurant.owner_id !== req.user.id && req.user.role !== 'admin')
      return res.status(403).json({ message: 'Yetki yok' });
  }

  const result = db.prepare(
    'INSERT INTO menu_items (restaurant_id, name, description, price, image_url, stock, is_available) VALUES (?,?,?,?,?,?,1)'
  ).run(restId, name, description, price, image_url, stock ?? 100);

  res.status(201).json({ id: result.lastInsertRowid, name, price });
}

/**
 * Mevcut bir ürünün fiyat, stok, isim gibi bilgilerini günceller.
 * Sahiplik doğrulamasından sonra sadece gönderilen değerleri COALESCE ile değiştirir.
 */
function update(req, res) {
  const db = getDB();
  const item = db.prepare('SELECT * FROM menu_items WHERE id=?').get(req.params.id);
  if (!item) return res.status(404).json({ message: 'Ürün bulunamadı' });

  const restaurant = db.prepare('SELECT owner_id FROM restaurants WHERE id=?').get(item.restaurant_id);
  if (restaurant.owner_id !== req.user.id && req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Bu ürünü düzenleme yetkiniz yok.' });
  }

  const { name, description, price, image_url, stock, is_available } = req.body;
  db.prepare(
    `UPDATE menu_items SET
       name=COALESCE(?,name),
       description=COALESCE(?,description),
       price=COALESCE(?,price),
       image_url=COALESCE(?,image_url),
       stock=COALESCE(?,stock),
       is_available=COALESCE(?,is_available)
     WHERE id=?`
  ).run(name, description, price, image_url, stock, is_available, req.params.id);

  res.json(db.prepare('SELECT * FROM menu_items WHERE id=?').get(req.params.id));
}

/**
 * Ürünü veritabanından kalıcı olarak silmek yerine (Soft Delete),
 * erişilebilirlik durumunu (is_available) pasife çeker.
 */
function remove(req, res) {
  const db = getDB();
  const item = db.prepare('SELECT * FROM menu_items WHERE id=?').get(req.params.id);
  if (!item) return res.status(404).json({ message: 'Ürün bulunamadı' });

  const restaurant = db.prepare('SELECT owner_id FROM restaurants WHERE id=?').get(item.restaurant_id);
  if (restaurant.owner_id !== req.user.id && req.user.role !== 'admin') {
    return res.status(403).json({ message: 'Bu ürünü silme yetkiniz yok.' });
  }

  db.prepare('UPDATE menu_items SET is_available=0 WHERE id=?').run(req.params.id);
  res.json({ message: 'Ürün kaldırıldı' });
}

module.exports = { listByRestaurant, getOwnerMenu, create, update, remove };