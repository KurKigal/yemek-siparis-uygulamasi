const { getDB } = require('../db/database');

/**
 * Aktif olan (silinmemiş) tüm restoranları listeler.
 * Eğer sorguda bir arama kelimesi (q) varsa restoran ismine göre filtreleme uygular.
 */
function list(req, res) {
  const { q } = req.query;
  const db = getDB();

  const rows = q
    ? db.prepare("SELECT * FROM restaurants WHERE is_active=1 AND name LIKE ?").all(`%${q}%`)
    : db.prepare("SELECT * FROM restaurants WHERE is_active=1").all();
  res.json(rows);
}

/**
 * Seçilen spesifik bir restoranın detay verilerini getirir.
 */
function detail(req, res) {
  const db = getDB();
  const r = db.prepare("SELECT * FROM restaurants WHERE id=? AND is_active=1").get(req.params.id);
  if (!r) return res.status(404).json({ message: 'Restoran bulunamadı' });
  res.json(r);
}

/**
 * Yeni bir restoran kaydı oluşturur.
 * İşlemi yapan Admin ise belirlediği ID'ye göre, Owner ise kendi ID'sine göre restoran açar.
 */
function create(req, res) {
  const { name, description, address, logo_url, owner_id } = req.body;
  if (!name) return res.status(400).json({ message: 'Restoran adı zorunludur' });

  const db = getDB();
  let finalOwnerId = req.user.id;

  if (req.user.role === 'admin' && owner_id) {
    finalOwnerId = owner_id;
  }

  const result = db.prepare(
    'INSERT INTO restaurants (owner_id, name, description, address, logo_url) VALUES (?,?,?,?,?)'
  ).run(finalOwnerId, name, description, address, logo_url);

  res.status(201).json({
    id: result.lastInsertRowid,
    owner_id: finalOwnerId,
    name,
    description,
    address,
    logo_url
  });
}

/**
 * Restoranın genel bilgilerini günceller.
 * COALESCE yapısı sayesinde sadece gönderilen (değişen) verilerin güncellenmesini sağlar.
 */
function update(req, res) {
  const db = getDB();
  const r = db.prepare('SELECT * FROM restaurants WHERE id=?').get(req.params.id);
  if (!r) return res.status(404).json({ message: 'Restoran bulunamadı' });

  if (r.owner_id !== req.user.id && req.user.role !== 'admin')
    return res.status(403).json({ message: 'Bu restoranı düzenleme yetkiniz yok' });

  const { name, description, address, logo_url } = req.body;

  db.prepare(
    'UPDATE restaurants SET name=COALESCE(?,name), description=COALESCE(?,description), address=COALESCE(?,address), logo_url=COALESCE(?,logo_url) WHERE id=?'
  ).run(name, description, address, logo_url, req.params.id);

  res.json(db.prepare('SELECT * FROM restaurants WHERE id=?').get(req.params.id));
}

/**
 * Restoran kaydını veritabanından silmek yerine durumunu pasife alır (Soft Delete).
 * Böylece geçmiş siparişlerdeki ilişkisel veriler bozulmaz.
 */
function remove(req, res) {
  const db = getDB();
  const r = db.prepare('SELECT * FROM restaurants WHERE id=?').get(req.params.id);
  if (!r) return res.status(404).json({ message: 'Restoran bulunamadı' });

  if (r.owner_id !== req.user.id && req.user.role !== 'admin')
    return res.status(403).json({ message: 'Yetki yok' });

  db.prepare('UPDATE restaurants SET is_active=0 WHERE id=?').run(req.params.id);
  res.json({ message: 'Restoran silindi' });
}

module.exports = { list, detail, create, update, remove };