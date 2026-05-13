import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/cart_item.dart';
import '../../menu/domain/menu_item_model.dart';

/**
 * Kullanıcının sepetindeki (cart) ürün listesini ve ürün miktarlarını
 * anlık olarak hafızada (state) tutan ve yöneten Riverpod durum yöneticisidir.
 */
class CartNotifier extends Notifier<List<CartItem>> {

  /**
   * Sağlayıcı ilk oluşturulduğunda sepeti boş bir liste olarak başlatır.
   */
  @override
  List<CartItem> build() => [];

  /**
   * Sepete yeni bir ürün ekler.
   * Eğer ürün halihazırda sepette varsa sadece miktarını (quantity) 1 arttırır.
   */
  void add(MenuItemModel item) {
    final idx = state.indexWhere((e) => e.menuItem.id == item.id);
    if (idx >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          i == idx ? state[i].copyWith(quantity: state[i].quantity + 1) : state[i]
      ];
    } else {
      state = [...state, CartItem(menuItem: item, quantity: 1)];
    }
  }

  /**
   * Sepetteki belirtilen ürünün miktarını 1 azaltır.
   * Eğer miktar 1 ise, o ürünü sepetten tamamen çıkartır.
   */
  void remove(int menuItemId) {
    final idx = state.indexWhere((e) => e.menuItem.id == menuItemId);
    if (idx < 0) return;
    final current = state[idx];
    if (current.quantity <= 1) {
      state = state.where((e) => e.menuItem.id != menuItemId).toList();
    } else {
      state = [
        for (int i = 0; i < state.length; i++)
          i == idx ? state[i].copyWith(quantity: state[i].quantity - 1) : state[i]
      ];
    }
  }

  /**
   * Sepetteki tüm ürünleri temizler ve sepeti sıfırlar.
   */
  void clear() => state = [];

  /**
   * Belirtilen bir ürünün sepette anlık olarak kaç adet bulunduğunu döndürür.
   */
  int quantityOf(int menuItemId) =>
      state.where((e) => e.menuItem.id == menuItemId).fold(0, (s, e) => s + e.quantity);
}

/**
 * CartNotifier sınıfına uygulama genelinden erişebilmek için tanımlanan ana sağlayıcıdır.
 */
final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(CartNotifier.new);

/**
 * Sepetteki tüm ürünlerin fiyatlarını ve miktarlarını çarparak toplam ödenecek
 * tutarı hesaplayan ve döndüren yardımcı sağlayıcıdır.
 */
final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0, (s, e) => s + e.subtotal);
});

/**
 * Sepetteki farklı ürünlerin miktarlarını toplayarak sepet ikonunda gösterilecek
 * toplam ürün sayısını (badge) sağlayan sağlayıcıdır.
 */
final cartCountProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).fold(0, (s, e) => s + e.quantity);
});

/**
 * Sepete ilk eklenen ürünün hangi restorana ait olduğunu döndürür.
 * Bu sayede farklı restoranlardan aynı sepete ürün eklenmesini engellemek için kullanılabilir.
 */
final cartRestaurantIdProvider = Provider<int?>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.isEmpty ? null : cart.first.menuItem.restaurantId;
});