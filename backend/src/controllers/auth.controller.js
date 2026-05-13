const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { getDB } = require('../db/database');

/**
 * Kullanıcı bilgilerini içeren bir JWT (JSON Web Token) oluşturur.
 * Bu token, API isteklerinde kullanıcının kimliğini doğrulamak için kullanılır.
 */
function generateToken(user) {
  return jwt.sign(
    { id: user.id, email: user.email, role: user.role },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN }
  );
}

/**
 * Yeni kullanıcı kaydı işlemini gerçekleştirir.
 * Gelen şifreyi bcrypt ile şifreleyerek veritabanına kaydeder ve token döndürür.
 */
async function register(req, res, next) {
  try {
    const { name, email, password, role = 'customer' } = req.body;

    if (!name || !email || !password)
      return res.status(400).json({ message: 'Ad, e-posta ve şifre zorunludur' });

    const allowedRoles = ['customer', 'restaurant_owner'];
    if (!allowedRoles.includes(role))
      return res.status(400).json({ message: 'Geçersiz rol' });

    const db = getDB();
    const existing = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
    if (existing)
      return res.status(409).json({ message: 'Bu e-posta zaten kayıtlı' });

    const hashed = await bcrypt.hash(password, 10);
    const result = db.prepare(
      'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)'
    ).run(name, email, hashed, role);

    const user = { id: result.lastInsertRowid, name, email, role };
    const token = generateToken(user);

    res.status(201).json({ user, token });
  } catch (err) {
    next(err);
  }
}

/**
 * Kullanıcı girişi işlemini gerçekleştirir.
 * Şifre doğrulaması başarılı olursa istemciye güvenli kullanıcı verisini ve token'ı iletir.
 */
async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    if (!email || !password)
      return res.status(400).json({ message: 'E-posta ve şifre zorunludur' });

    const db = getDB();
    const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
    if (!user)
      return res.status(401).json({ message: 'E-posta veya şifre hatalı' });

    const match = await bcrypt.compare(password, user.password);
    if (!match)
      return res.status(401).json({ message: 'E-posta veya şifre hatalı' });

    const token = generateToken(user);
    const { password: _, ...safeUser } = user;
    res.json({ user: safeUser, token });
  } catch (err) {
    next(err);
  }
}

/**
 * Sisteme giriş yapmış olan kullanıcının kendi profil bilgilerini getirir.
 */
function getMe(req, res) {
  const db = getDB();
  const user = db.prepare(
    'SELECT id, name, email, role, created_at FROM users WHERE id = ?'
  ).get(req.user.id);

  if (!user) return res.status(404).json({ message: 'Kullanıcı bulunamadı' });
  res.json(user);
}

/**
 * Kullanıcının kendi adını veya şifresini güncellemesini sağlar.
 */
async function updateMe(req, res, next) {
  try {
    const { name, password } = req.body;
    const db = getDB();

    if (password) {
      const hashed = await bcrypt.hash(password, 10);
      db.prepare('UPDATE users SET password = ? WHERE id = ?').run(hashed, req.user.id);
    }
    if (name) {
      db.prepare('UPDATE users SET name = ? WHERE id = ?').run(name, req.user.id);
    }

    const updated = db.prepare(
      'SELECT id, name, email, role, created_at FROM users WHERE id = ?'
    ).get(req.user.id);

    res.json(updated);
  } catch (err) {
    next(err);
  }
}

/**
 * Güvenli şifre değiştirme işlemidir.
 * İşlemin gerçekleşmesi için kullanıcının eski şifresini doğru girmesi zorunludur.
 */
async function changePassword(req, res, next) {
  try {
    const { oldPassword, newPassword } = req.body;
    const userId = req.user.id;

    if (!oldPassword || !newPassword) {
      return res.status(400).json({ message: 'Eski ve yeni şifre zorunludur.' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Yeni şifre en az 6 karakter olmalıdır.' });
    }

    const db = getDB();
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);

    if (!user) {
      return res.status(404).json({ message: 'Kullanıcı bulunamadı.' });
    }

    const isMatch = await bcrypt.compare(oldPassword, user.password);
    if (!isMatch) {
      return res.status(400).json({ message: 'Mevcut şifreniz yanlış.' });
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    db.prepare('UPDATE users SET password = ? WHERE id = ?').run(hashedPassword, userId);

    res.json({ message: 'Şifreniz başarıyla güncellendi.' });
  } catch (err) {
    next(err);
  }
}

/**
 * Sadece 'Müşteri' (customer) rolündeki kullanıcıların profil bilgilerini günceller.
 * COALESCE fonksiyonu ile sadece gönderilen alanların değiştirilmesini sağlar.
 */
async function updateProfile(req, res, next) {
  try {
    if (req.user.role !== 'customer') {
      return res.status(403).json({ message: 'Sadece müşteriler profil bilgilerini güncelleyebilir.' });
    }

    const { name, email } = req.body;
    const db = getDB();

    if (email) {
      const existingUser = db.prepare('SELECT id FROM users WHERE email = ? AND id != ?').get(email, req.user.id);
      if (existingUser) {
        return res.status(400).json({ message: 'Bu e-posta adresi zaten başka bir hesap tarafından kullanılıyor.' });
      }
    }

    db.prepare(`
      UPDATE users
      SET name = COALESCE(?, name),
          email = COALESCE(?, email)
      WHERE id = ?
    `).run(name, email, req.user.id);

    const updatedUser = db.prepare(
      'SELECT id, name, email, role, created_at FROM users WHERE id = ?'
    ).get(req.user.id);

    res.json(updatedUser);
  } catch (err) {
    next(err);
  }
}

module.exports = { register, login, getMe, updateMe, changePassword, updateProfile };