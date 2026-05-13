// Veritabanını örnek (dummy) verilerle doldurmak için gerekli modüller içe aktarılır.
const { initDB, getDB } = require('./database');
const bcrypt = require('bcryptjs');

// Veritabanını sıfırlayıp yeniden test verisiyle dolduran asenkron ana fonksiyon.
async function seed() {
  initDB();
  const db = getDB();

  console.log('🌱 Seed başlıyor...\n');

  // Mevcut veritabanındaki tüm tabloları ve otomatik artan (AUTOINCREMENT) sayaçları sıfırlar.
  db.exec(`
    DELETE FROM order_items;
    DELETE FROM orders;
    DELETE FROM menu_items;
    DELETE FROM restaurants;
    DELETE FROM users;
    DELETE FROM sqlite_sequence WHERE name IN
      ('users','restaurants','menu_items','orders','order_items');
  `);

  // Güvenlik amacıyla kullanıcı şifrelerini hash'lemek (şifrelemek) için yardımcı fonksiyon.
  const hash = (pw) => bcrypt.hashSync(pw, 10);

  // Sistem için farklı rollerde (Admin, Restoran Sahibi, Müşteri) test kullanıcıları oluşturulur.
  const users = db.prepare(
    'INSERT INTO users (name, email, password, role) VALUES (?, ?, ?, ?)'
  );

  const adminId = users.run(
    'Admin', 'admin@test.com', hash('admin123'), 'admin'
  ).lastInsertRowid;

  const owner1Id = users.run(
    'Ahmet Yılmaz', 'ahmet@test.com', hash('owner123'), 'restaurant_owner'
  ).lastInsertRowid;

  const owner2Id = users.run(
    'Fatma Kaya', 'fatma@test.com', hash('owner123'), 'restaurant_owner'
  ).lastInsertRowid;

  const owner3Id = users.run(
    'Mehmet Demir', 'mehmet@test.com', hash('owner123'), 'restaurant_owner'
  ).lastInsertRowid;

  const customer1Id = users.run(
    'Ali Öztürk', 'ali@test.com', hash('user123'), 'customer'
  ).lastInsertRowid;

  const customer2Id = users.run(
    'Zeynep Şahin', 'zeynep@test.com', hash('user123'), 'customer'
  ).lastInsertRowid;

  console.log('✅ Kullanıcılar eklendi');

  // Oluşturulan restoran sahiplerine ait örnek restoranlar veritabanına eklenir.
  const insertRestaurant = db.prepare(`
    INSERT INTO restaurants (owner_id, name, description, address, logo_url, rating)
    VALUES (?, ?, ?, ?, ?, ?)
  `);

  const r1 = insertRestaurant.run(
    owner1Id,
    'Burgerci Ahmet',
    'İstanbul\'un en lezzetli el yapımı burgerleri. 1987\'den beri aynı tarif, aynı tutku.',
    'Kadıköy, İstanbul',
    'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80',
    4.7
  ).lastInsertRowid;

  const r2 = insertRestaurant.run(
    owner2Id,
    'Pizza Fatma',
    'Odun ateşinde pişirilmiş otantik İtalyan pizzaları. Napoli usulü ince hamur.',
    'Beşiktaş, İstanbul',
    'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80',
    4.5
  ).lastInsertRowid;

  const r3 = insertRestaurant.run(
    owner3Id,
    'Sushi Mehmet',
    'Taze deniz ürünleriyle hazırlanan otantik Japon mutfağı. Günlük taze balık garantisi.',
    'Nişantaşı, İstanbul',
    'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?w=800&q=80',
    4.8
  ).lastInsertRowid;

  const r4 = insertRestaurant.run(
    owner1Id,
    'Dönerci Ustası',
    'Geleneksel Türk döner kebabı. Dana eti, özel baharatlar ve taze ekmek.',
    'Üsküdar, İstanbul',
    'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=800&q=80',
    4.3
  ).lastInsertRowid;

  const r5 = insertRestaurant.run(
    owner2Id,
    'Vegan Köşe',
    '100% bitkisel, sağlıklı ve lezzetli. Glutensiz seçenekler mevcuttur.',
    'Şişli, İstanbul',
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80',
    4.2
  ).lastInsertRowid;

  console.log('✅ Restoranlar eklendi');

  // Restoranların menü öğeleri fiyat ve stok bilgileriyle birlikte sisteme tanıtılır.
  const insertItem = db.prepare(`
    INSERT INTO menu_items (restaurant_id, name, description, price, image_url, stock)
    VALUES (?, ?, ?, ?, ?, ?)
  `);

  const smashId = insertItem.run(r1,
    'Smash Burger',
    'İki adet ince patty, çift cheddar, özel sos, turşu ve soğan. Klasik lezzet.',
    149.90,
    'https://images.unsplash.com/photo-1551782450-17144efb9c50?w=400&q=80',
    50
  ).lastInsertRowid;

  insertItem.run(r1,
    'BBQ Burger',
    'Izgara patty, BBQ sos, karamelize soğan, bacon ve marul. Dumanlı lezzet.',
    169.90,
    'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=400&q=80',
    40
  );

  insertItem.run(r1,
    'Chicken Burger',
    'Çıtır tavuk, ranch sos, domates ve marul. Hafif ve doyurucu.',
    139.90,
    'https://images.unsplash.com/photo-1627485937980-221c88ac04f9?w=400&q=80',
    45
  );

  insertItem.run(r1,
    'Patates Kızartması',
    'İnce doğranmış, çıtır çıtır. Yanında ketçap ve mayonez.',
    49.90,
    'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&q=80',
    100
  );

  insertItem.run(r1,
    'Soğan Halkası',
    'Çıtır panko kaplama soğan halkası. Ranch sos eşliğinde.',
    54.90,
    'https://images.unsplash.com/photo-1639024471283-03518883512d?w=400&q=80',
    80
  );

  insertItem.run(r1,
    'Milkshake',
    'Çikolata, çilek veya vanilyalı. Kremalı ve kalın doku.',
    69.90,
    'https://images.unsplash.com/photo-1572490122747-3968b75cc699?w=400&q=80',
    60
  );

  const margheritaId = insertItem.run(r2,
    'Margherita',
    'San Marzano domates sosu, bufala mozzarella ve taze fesleğen. İtalyan klasiği.',
    159.00,
    'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=400&q=80',
    30
  ).lastInsertRowid;

  insertItem.run(r2,
    'Pepperoni',
    'Bol pepperoni, mozzarella ve domates sosu. Herkesin favorisi.',
    179.00,
    'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400&q=80',
    30
  );

  insertItem.run(r2,
    'Quattro Formaggi',
    'Dört peynir: mozzarella, gorgonzola, parmigiano ve ricotta. Peynir severler için.',
    199.00,
    'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400&q=80',
    25
  );

  insertItem.run(r2,
    'Truffle Mantarlı',
    'Truffle yağı, karışık mantar, parmesan ve roka. Gurme seçim.',
    229.00,
    'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=400&q=80',
    20
  );

  insertItem.run(r2,
    'Tiramisu',
    'Geleneksel İtalyan tatlısı. Mascarpone, espresso ve kakao.',
    89.00,
    'https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400&q=80',
    40
  );

  const salmonId = insertItem.run(r3,
    'Somon Nigiri (8 adet)',
    'Taze somon, suşi pirinci ve wasabi. Günlük taze balık garantisi.',
    189.00,
    'https://images.unsplash.com/photo-1617196034183-421b4040ed20?w=400&q=80',
    25
  ).lastInsertRowid;

  insertItem.run(r3,
    'Dragon Roll (8 adet)',
    'Karides tempura, avokado ve somon. Üzerinde sriracha sos.',
    229.00,
    'https://images.unsplash.com/photo-1617196034099-b75a2e3e6b0b?w=400&q=80',
    20
  );

  insertItem.run(r3,
    'Rainbow Roll (10 adet)',
    'İçinde ton balığı, üzerinde 5 farklı balık. Rengarenk sumo tabağı.',
    279.00,
    'https://images.unsplash.com/photo-1611143669185-af224c5e3252?w=400&q=80',
    15
  );

  insertItem.run(r3,
    'Miso Çorba',
    'Geleneksel Japon miso çorbası, tofu ve deniz yosunu ile.',
    59.00,
    'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400&q=80',
    50
  );

  insertItem.run(r3,
    'Edamame',
    'Buharda pişirilmiş soya fasulyesi, deniz tuzu ile.',
    49.00,
    'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400&q=80',
    60
  );

  insertItem.run(r4,
    'Döner Dürüm',
    'Dana döner, közlenmiş biber, soğan, domates ve özel sos. Lavaş ekmeğinde.',
    99.90,
    'https://images.unsplash.com/photo-1603360946369-dc9bb6258143?w=400&q=80',
    80
  );

  insertItem.run(r4,
    'Döner Tabak',
    'Bol döner, pirinç pilavı, cacık ve salata. Doyurucu porsiyon.',
    129.90,
    'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=400&q=80',
    60
  );

  insertItem.run(r4,
    'Tavuk Döner Dürüm',
    'Izgara tavuk döner, taze sebzeler ve yoğurtlu sos.',
    89.90,
    'https://images.unsplash.com/photo-1561626423-a51b45aef0a1?w=400&q=80',
    80
  );

  insertItem.run(r4,
    'Ayran',
    'Soğuk, köpüklü, geleneksel Türk ayranı.',
    24.90,
    'https://images.unsplash.com/photo-1571115177098-24ec42ed204d?w=400&q=80',
    200
  );

  insertItem.run(r5,
    'Nohut Burger',
    'Ev yapımı nohut köftesi, avokado, domates ve taze yeşillik. Glutensiz ekmek.',
    129.00,
    'https://images.unsplash.com/photo-1520072959219-c595dc870360?w=400&q=80',
    40
  );

  insertItem.run(r5,
    'Budha Bowl',
    'Kinoa, kavrulmuş nohut, avokado, turp, havuç ve tahin sos.',
    149.00,
    'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400&q=80',
    35
  );

  insertItem.run(r5,
    'Smoothie Bowl',
    'Açaí, muz, çilek, granola ve taze meyveler. Enerji dolu başlangıç.',
    109.00,
    'https://images.unsplash.com/photo-1590301157890-4810ed352733?w=400&q=80',
    30
  );

  insertItem.run(r5,
    'Yeşil Detoks',
    'Ispanak, elma, zencefil, limon ve salatalık. Taze sıkılmış.',
    79.00,
    'https://images.unsplash.com/photo-1610970881699-44a5587cabec?w=400&q=80',
    50
  );

  console.log('✅ Menü öğeleri eklendi');

  // Sipariş işlemleri ve sipariş içeriklerinin simüle edilmesi.
  const insertOrder = db.prepare(`
    INSERT INTO orders (user_id, restaurant_id, total_price, status, payment_status, address, created_at)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `);
  const insertOrderItem = db.prepare(`
    INSERT INTO order_items (order_id, menu_item_id, quantity, unit_price)
    VALUES (?, ?, ?, ?)
  `);

  const o1 = insertOrder.run(
    customer1Id, r1, 349.60, 'teslim_edildi', 'odendi',
    'Moda Cad. No:12, Kadıköy',
    new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString()
  ).lastInsertRowid;
  insertOrderItem.run(o1, smashId, 2, 149.90);

  const o2 = insertOrder.run(
    customer1Id, r2, 338.00, 'yolda', 'odendi',
    'Barbaros Blv. No:45, Beşiktaş',
    new Date(Date.now() - 30 * 60 * 1000).toISOString()
  ).lastInsertRowid;
  insertOrderItem.run(o2, margheritaId, 1, 159.00);

  const o3 = insertOrder.run(
    customer2Id, r3, 248.00, 'hazirlaniyor', 'odendi',
    'Abdi İpekçi Cad. No:7, Nişantaşı',
    new Date(Date.now() - 10 * 60 * 1000).toISOString()
  ).lastInsertRowid;
  insertOrderItem.run(o3, salmonId, 1, 189.00);

  const o4 = insertOrder.run(
    customer2Id, r1, 219.80, 'teslim_edildi', 'odendi',
    'Bağdat Cad. No:88, Kadıköy',
    new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString()
  ).lastInsertRowid;
  insertOrderItem.run(o4, smashId, 1, 149.90);

  console.log('✅ Siparişler eklendi');

  // Konsol üzerinde başarılı seed işlemi özet raporu yazdırılır.
  console.log('\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('🎉 Seed tamamlandı!\n');
  console.log('👤 Test Hesapları:');
  console.log('─────────────────────────────────────────');
  console.log('  Müşteri 1 → ali@test.com      / user123');
  console.log('  Müşteri 2 → zeynep@test.com   / user123');
  console.log('  Sahip 1   → ahmet@test.com    / owner123');
  console.log('  Sahip 2   → fatma@test.com    / owner123');
  console.log('  Admin     → admin@test.com    / admin123');
  console.log('─────────────────────────────────────────');
  console.log(`  🏪 ${db.prepare('SELECT COUNT(*) as c FROM restaurants').get().c} restoran`);
  console.log(`  🍔 ${db.prepare('SELECT COUNT(*) as c FROM menu_items').get().c} menü öğesi`);
  console.log(`  📦 ${db.prepare('SELECT COUNT(*) as c FROM orders').get().c} sipariş`);
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
}

seed().catch(console.error);