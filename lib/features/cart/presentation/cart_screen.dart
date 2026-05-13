import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/loading_button.dart';
import 'cart_provider.dart';

/**
 * Sayfa içerisindeki sipariş yüklenme durumunu ve teslimat adresini
 * geçici olarak hafızada tutan lokal Riverpod sağlayıcıları.
 */
final _orderLoadingProvider = StateProvider<bool>((ref) => false);
final _deliveryAddressProvider = StateProvider<String>((ref) => '');

/**
 * Kullanıcının sepetindeki ürünleri görüntülediği, teslimat adresi girdiği
 * ve sipariş sürecini başlattığı arayüz bileşeni.
 */
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart      = ref.watch(cartProvider);
    final total     = ref.watch(cartTotalProvider);
    final isLoading = ref.watch(_orderLoadingProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sepetim', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (cart.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: const Text('Temizle', style: TextStyle(color: Colors.red)),
            ),
        ],
      ),
      body: cart.isEmpty
      // Sepet boş olduğunda kullanıcıyı restoranlar sayfasına yönlendiren bilgi ekranı
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.shopping_cart_outlined, size: 72, color: Colors.grey[300]),
        const SizedBox(height: 16),
        const Text('Sepetiniz boş',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go('/restaurants'),
          child: const Text('Restoranlara git'),
        ),
      ]))
          : Column(children: [
        // Sepete eklenen ürünlerin listelendiği kaydırılabilir alan
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cart.length,
            itemBuilder: (context, index) => _CartItemTile(cartItem: cart[index]),
          ),
        ),

        // Teslimat adresi girişi ve toplam tutarın gösterildiği alt panel
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 12,
                offset: const Offset(0, -4),
              )
            ],
          ),
          child: SafeArea(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Teslimat Adresi',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Adresinizi girin...',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onChanged: (v) =>
                ref.read(_deliveryAddressProvider.notifier).state = v,
              ),
              const SizedBox(height: 16),

              Row(children: [
                const Text('Toplam', style: TextStyle(fontSize: 15)),
                const Spacer(),
                Text('₺${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    )),
              ]),
              const SizedBox(height: 14),

              LoadingButton(
                text: 'Siparişi Tamamla',
                isLoading: isLoading,
                onPressed: () => _placeOrder(context, ref),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  /**
   * Sepet verilerini derleyip backend'e sipariş oluşturma isteği gönderen
   * ve başarılı olursa ödeme simülasyonu ekranına yönlendiren asenkron fonksiyon.
   */
  Future<void> _placeOrder(BuildContext context, WidgetRef ref) async {
    final address = ref.read(_deliveryAddressProvider);
    if (address.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen teslimat adresi girin')),
      );
      return;
    }

    final cart         = ref.read(cartProvider);
    final restaurantId = ref.read(cartRestaurantIdProvider);
    if (restaurantId == null) return;

    ref.read(_orderLoadingProvider.notifier).state = true;
    try {
      final dio = ref.read(dioProvider);

      final items = cart.map((e) => {
        'menu_item_id': e.menuItem.id,
        'quantity': e.quantity,
      }).toList();

      final res = await dio.post(ApiConstants.orders, data: {
        'restaurant_id': restaurantId,
        'items': items,
        'address': address,
      });

      final orderId = res.data['id'];
      final total = ref.read(cartTotalProvider);

      ref.read(cartProvider.notifier).clear();

      if (!context.mounted) return;

      context.push('/payment/$orderId?amount=$total');

    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
      );
    } finally {
      ref.read(_orderLoadingProvider.notifier).state = false;
    }
  }
}

/**
 * Sepet listesindeki her bir ürünün adını, fiyatını, resmini ve miktar
 * artırma/azaltma butonlarını içeren satır bileşeni.
 */
class _CartItemTile extends ConsumerWidget {
  final dynamic cartItem;
  const _CartItemTile({required this.cartItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = cartItem.menuItem;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: item.imageUrl != null
              ? Image.network(item.imageUrl!,
              width: 60, height: 60, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _placeholder())
              : _placeholder(),
        ),
        const SizedBox(width: 12),

        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('₺${item.price.toStringAsFixed(2)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
        ])),

        Row(children: [
          _Btn(Icons.remove,
                  () => ref.read(cartProvider.notifier).remove(item.id)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text('${cartItem.quantity}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          _Btn(Icons.add,
                  () => ref.read(cartProvider.notifier).add(item)),
        ]),

        const SizedBox(width: 8),
        Text('₺${cartItem.subtotal.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor)),
      ]),
    );
  }

  /**
   * Ürün görseli yüklenemediğinde veya bulunmadığında gösterilen alternatif yer tutucu.
   */
  Widget _placeholder() => Container(
      width: 60, height: 60, color: Colors.grey[100],
      child: const Icon(Icons.fastfood, color: Colors.grey, size: 28));
}

/**
 * Ürün miktarını değiştirmek (artı/eksi) için kullanılan özelleştirilmiş buton tasarımı.
 */
class _Btn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _Btn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withAlpha(25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 16, color: AppTheme.primaryColor),
    ),
  );
}