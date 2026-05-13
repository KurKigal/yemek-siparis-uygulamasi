import '../../menu/domain/menu_item_model.dart';

/**
 * Sepette (Cart) tutulan ürünün yapısını ve adet bilgisini temsil eden veri modeli.
 */
class CartItem {
  final MenuItemModel menuItem;
  final int quantity;

  const CartItem({required this.menuItem, required this.quantity});

  /**
   * İlgili ürünün fiyatı ile o üründen sepette kaç adet eklendiğini
   * çarparak o ürün için oluşan ara toplamı hesaplar.
   */
  double get subtotal => menuItem.price * quantity;

  /**
   * Değişmez (Immutable) yapıyı koruyarak sadece istenen özelliğin (adet gibi)
   * güncellendiği yeni bir kopya nesne oluşturur.
   */
  CartItem copyWith({int? quantity}) =>
      CartItem(menuItem: menuItem, quantity: quantity ?? this.quantity);
}