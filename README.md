# 🍔 Yemek Sipariş Uygulaması  (Food Delivery App)

Bu proje, çok rollü (Müşteri, Restoran Sahibi, Admin) kapsamlı bir yemek sipariş uygulamasıdır. 

Frontend tarafında **Flutter** kullanılarak modern ve performanslı bir kullanıcı deneyimi hedeflenmiş, backend tarafında ise **Node.js, Express ve SQLite** ile güvenli ve hızlı bir altyapı kurulmuştur.

---

## 📸 Ekran Görüntüleri



### 🧑‍💻 Müşteri (Customer) Paneli
| Ana Sayfa (Restoranlar) | Sepet & Ödeme | Sipariş Geçmişi |
| :---: | :---: | :---: |
| <img width="395" height="882" alt="resim" src="https://github.com/user-attachments/assets/0fddfc00-a8bc-4795-b6b1-d3bbad610a7a" /> | <img width="395" height="880" alt="sepet" src="https://github.com/user-attachments/assets/8c8ae28b-055d-4c38-8a9f-465ee3edaf99" /> | <img width="397" height="873" alt="gecmis" src="https://github.com/user-attachments/assets/e1545345-c230-4cd0-b4a2-aac31956416b" /> | 

### 🏪 Restoran Sahibi (Owner) Paneli
| Gelen Siparişler | Menü Yönetimi | Sahip Profil & İstatistik |
| :---: | :---: | :---: |
| <img width="395" height="871" alt="gelens" src="https://github.com/user-attachments/assets/b6abc0c5-95e9-40fa-84be-594c0e885489" /> | <img width="393" height="879" alt="menu" src="https://github.com/user-attachments/assets/bb6e2bc0-5fb2-441e-a81a-f30b1b078a1d" /> | <img width="393" height="870" alt="pro" src="https://github.com/user-attachments/assets/86db130b-d1b6-4ddb-920c-37141aefc2eb" /> |

### 🛡️ Admin & Kimlik Doğrulama
| Admin Paneli | Giriş Yap | Kayıt Ol |
| :---: | :---: | :---: |
| a<img width="393" height="875" alt="admin" src="https://github.com/user-attachments/assets/be6528c6-72ec-4fbb-a9f1-f396b635a926" /> | <img width="394" height="875" alt="kayit" src="https://github.com/user-attachments/assets/06ee38c8-bb8e-4a16-b94a-aaff2541b865" /> | <img width="392" height="880" alt="giris" src="https://github.com/user-attachments/assets/4f037e2b-2331-480a-af3b-24c3467c85a6" /> |

---

## 🚀 Temel Özellikler

Uygulama, üç farklı kullanıcı rolüne göre özelleştirilmiş arayüzler ve yetkiler sunar:

### 1. Müşteri (Customer)
* **Kategori Bazlı Filtreleme:** Restoranları türlerine göre (Pizza, Burger, Tatlı vb.) filtreleme ve arama yapabilme.
* **Sepet Yönetimi:** Ürün adetlerini artırma/azaltma, sepet tutarını anlık görüntüleme. (Farklı restoranlardan aynı anda ürün eklemeyi engelleyen güvenlik kontrolü).
* **Ödeme Simülasyonu:** Sanal ödeme adımı (1000 TL üzeri şüpheli işlemleri reddetme simülasyonu).
* **Sipariş Takibi:** Hazırlanıyor, Yolda, Teslim Edildi aşamalarını görsel ilerleme çubuğu ile takip etme.
* **Profil Yönetimi:** Kişisel bilgileri ve şifreyi güvenle güncelleyebilme.

### 2. Restoran Sahibi (Restaurant Owner)
* **Sipariş Yönetimi:** Kendi restoranına düşen siparişleri anlık görüntüleme ve durumlarını (Hazırlanıyor -> Yolda -> Teslim Edildi) güncelleme.
* **Menü Yönetimi (CRUD):** Yeni ürün ekleme, fiyat/stok güncelleme, ürün kaldırma (Soft Delete).
* **Finansal İstatistikler:** Gelen sipariş, tamamlanan sipariş ve toplam kazanç istatistiklerini görüntüleme.

### 3. Yönetici (Admin)
* **Restoran Yönetimi:** Sisteme yeni restoran ekleme, mevcut restoranları düzenleme ve pasife alma (Soft Delete).

---

## 🛠️ Kullanılan Teknolojiler ve Mimari

**Frontend (Mobil Uygulama):**
* **Flutter & Dart**
* **State Management:** Riverpod (Notifier, FutureProvider, StateProvider vb. kullanılarak reaktif yapı)
* **Routing:** GoRouter (Rol bazlı sayfa yönlendirmeleri ve Guard mekanizması)
* **Network:** Dio (Interceptor ile otomatik Token ekleme ve hata yakalama)
* **Storage:** Flutter Secure Storage (JWT Token'ı güvenli saklama)

**Backend (API):**
* **Node.js & Express.js**
* **Veritabanı:** SQLite (better-sqlite3)
* **Güvenlik:** JWT (JSON Web Token) tabanlı yetkilendirme, bcryptjs (Şifre hashleme)

---

## ⚙️ Kurulum ve Çalıştırma

Projeyi yerel ortamınızda çalıştırmak için aşağıdaki adımları izleyin.

### 1. Backend Kurulumu
1. \`backend\` klasörüne gidin: \`cd backend\`
2. Gerekli paketleri yükleyin: \`npm install\`
3. Örnek test verilerini (dummy veri) ve veritabanını oluşturmak için seed dosyasını çalıştırın:
   \`node seed.js\`
4. Sunucuyu başlatın:
   \`npm start\`

### 2. Frontend (Flutter) Kurulumu
1. Proje ana dizinine (veya flutter klasörüne) gidin.
2. Gerekli paketleri yükleyin: \`flutter pub get\`
3. Uygulamayı çalıştırın: \`flutter run\`
*(Not: Backend yerelde çalıştığı için \`lib/core/constants/api_constants.dart\` dosyasındaki \`baseUrl\` adresinin cihazınıza (Emülatör için \`10.0.2.2\`, gerçek cihaz için yerel IP) uygun olduğundan emin olun.)*

---

## 👤 Test Hesapları

\`seed.js\` çalıştırıldığında sistemde otomatik olarak oluşturulan test hesapları:

* **Admin:** \`admin@test.com\` / Şifre: \`admin123\`
* **Restoran Sahibi 1:** \`ahmet@test.com\` / Şifre: \`owner123\`
* **Restoran Sahibi 2:** \`fatma@test.com\` / Şifre: \`owner123\`
* **Müşteri 1:** \`ali@test.com\` / Şifre: \`user123\`
* **Müşteri 2:** \`zeynep@test.com\` / Şifre: \`user123\`
