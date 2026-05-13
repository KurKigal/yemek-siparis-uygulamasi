/**
 * Sistemdeki restoranları temsil eden temel veri modeli sınıfıdır.
 * Restoranın adı, adresi, logosu ve puanı gibi bilgileri güvenli bir yapıda tutar.
 */
class RestaurantModel {
  final int id;                 // Restoranın benzersiz kimlik numarası
  final String name;            // Restoranın adı
  final String? description;    // Restoran hakkında kısa açıklama (isteğe bağlı)
  final String? address;        // Restoranın açık adresi (isteğe bağlı)
  final String? logoUrl;        // Restoran logosunun internet adresi (isteğe bağlı)
  final double rating;          // Restoranın müşteri değerlendirme puanı

  const RestaurantModel({
    required this.id,
    required this.name,
    this.description,
    this.address,
    this.logoUrl,
    this.rating = 0, // Belirtilmediğinde varsayılan puan 0 olarak kabul edilir
  });

  /**
   * Backend'den gelen JSON formatındaki veriyi RestaurantModel nesnesine dönüştüren
   * fabrika (factory) metodudur. Değerlerin güvenli bir şekilde (null check ve tip dönüşümü)
   * eşleştirilmesini sağlar.
   */
  factory RestaurantModel.fromJson(Map<String, dynamic> j) => RestaurantModel(
    id:          j['id'],
    name:        j['name'],
    description: j['description'],
    address:     j['address'],
    logoUrl:     j['logo_url'],
    rating:      (j['rating'] as num?)?.toDouble() ?? 0,
  );
}