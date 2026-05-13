/**
 * Restoran menüsünde yer alan her bir yiyecek veya içecek kalemini temsil eden veri modelidir.
 * Bu sınıf, ürünün adı, fiyatı, açıklaması, stok durumu ve görseli gibi temel bilgileri barındırır.
 */
class MenuItemModel {
  final int id;              // Ürünün benzersiz kimlik numarası
  final int restaurantId;    // Ürünün ait olduğu restoranın kimlik numarası
  final String name;         // Ürünün adı
  final String? description; // Ürün hakkında kısa açıklama (isteğe bağlı)
  final double price;        // Ürünün birim fiyatı
  final String? imageUrl;    // Ürüne ait görselin internet adresi
  final int stock;           // Ürünün depodaki mevcut stok miktarı

  const MenuItemModel({
    required this.id,
    required this.restaurantId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    this.stock = 100, // Varsayılan stok miktarı 100 olarak belirlenmiştir
  });

  /**
   * Backend'den gelen JSON formatındaki veriyi MenuItemModel nesnesine dönüştüren fabrika metodudur.
   * Fiyat verisinin doğruluğu için 'num' tipinden 'double' tipine güvenli dönüşüm yapar.
   */
  factory MenuItemModel.fromJson(Map<String, dynamic> j) => MenuItemModel(
    id:           j['id'],
    restaurantId: j['restaurant_id'],
    name:         j['name'],
    description:  j['description'],
    price:        (j['price'] as num).toDouble(),
    imageUrl:     j['image_url'],
    stock:        j['stock'] ?? 100,
  );
}