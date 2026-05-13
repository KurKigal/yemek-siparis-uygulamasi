// SQLite veritabanı bağlantısını sağlamak için gerekli kütüphaneler içe aktarılır.
const Database = require('better-sqlite3');
const path = require('path');

// Veritabanı dosyasının sunucu üzerindeki fiziksel konumu belirlenir.
const DB_PATH = path.join(__dirname, '../../yemek.db');
let db;

// Veritabanı bağlantısını başlatan ve Singleton mantığıyla çalışan fonksiyon.
// Eğer bağlantı daha önce açılmamışsa yeni bir bağlantı oluşturur, aksi halde mevcut olanı döndürür.
function getDB() {
  if (!db) db = new Database(DB_PATH);
  return db;
}

// Veritabanı tablolarının şemasını (schema) oluşturan başlatıcı fonksiyon.
// Uygulama ilk kez çalıştığında tablolar yoksa otomatik olarak inşa edilmelerini sağlar.
function initDB() {
  const db = getDB();

  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT DEFAULT 'customer',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    );

    CREATE TABLE IF NOT EXISTS restaurants (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      owner_id INTEGER,
      name TEXT NOT NULL,
      description TEXT,
      address TEXT,
      logo_url TEXT,
      rating REAL DEFAULT 0,
      is_active INTEGER DEFAULT 1,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (owner_id) REFERENCES users(id)
    );

    CREATE TABLE IF NOT EXISTS menu_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      restaurant_id INTEGER NOT NULL,
      name TEXT NOT NULL,
      description TEXT,
      price REAL NOT NULL,
      image_url TEXT,
      stock INTEGER DEFAULT 100,
      is_available INTEGER DEFAULT 1,
      FOREIGN KEY (restaurant_id) REFERENCES restaurants(id)
    );

    CREATE TABLE IF NOT EXISTS orders (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL,
      restaurant_id INTEGER NOT NULL,
      total_price REAL NOT NULL,
      status TEXT DEFAULT 'hazirlaniyor',
      payment_status TEXT DEFAULT 'bekliyor',
      address TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      FOREIGN KEY (user_id) REFERENCES users(id),
      FOREIGN KEY (restaurant_id) REFERENCES restaurants(id)
    );

    CREATE TABLE IF NOT EXISTS order_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      order_id INTEGER NOT NULL,
      menu_item_id INTEGER NOT NULL,
      quantity INTEGER NOT NULL,
      unit_price REAL NOT NULL,
      FOREIGN KEY (order_id) REFERENCES orders(id),
      FOREIGN KEY (menu_item_id) REFERENCES menu_items(id)
    );
  `);

  console.log('Veritabanı hazır ✓');
}

module.exports = { getDB, initDB };