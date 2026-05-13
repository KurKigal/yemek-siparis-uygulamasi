import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../menu/data/menu_repository.dart';
import '../../menu/domain/menu_item_model.dart';
import 'restaurant_provider.dart';

/**
 * Belirli bir restoranın detaylarını (kapak görseli, puan, adres) ve o
 * restorana ait menü ürünlerini listeleyen arayüz bileşeni.
 */
class RestaurantDetailScreen extends ConsumerWidget {
  final int id;
  const RestaurantDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Restoran detaylarını ve menü öğelerini asenkron olarak dinleyen sağlayıcılar.
    final restaurantAsync = ref.watch(restaurantDetailProvider(id));
    final menuAsync       = ref.watch(menuByRestaurantProvider(id));

    // Sepetteki toplam ürün sayısını takip eder (Sepet ikonu bildirimi için).
    final cartCount       = ref.watch(cartCountProvider);

    return Scaffold(
      body: restaurantAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Hata: $e')),
        data: (restaurant) => CustomScrollView(
          slivers: [
            // Sayfa aşağı kaydırıldığında küçülerek üst bar halini alan (Sliver) esnek görsel alanı.
            SliverAppBar(
              expandedHeight: 220,
              pinned: true,
              backgroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () => context.pop(),
              ),
              actions: [
                Stack(children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => context.go('/cart'),
                  ),
                  // Eğer sepette ürün varsa ikonun üzerinde küçük bir bildirim (badge) gösterilir.
                  if (cartCount > 0)
                    Positioned(
                      right: 6, top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                            color: AppTheme.primaryColor, shape: BoxShape.circle),
                        child: Text('$cartCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10)),
                      ),
                    ),
                ]),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: restaurant.logoUrl != null
                    ? Image.network(restaurant.logoUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Container(color: Colors.grey[200]))
                    : Container(color: Colors.grey[200],
                    child: const Icon(Icons.restaurant, size: 64, color: Colors.grey)),
              ),
            ),

            // Restoranın ad, puan, açıklama ve adres bilgilerinin yer aldığı sabit bölüm.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(restaurant.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                          color: Colors.amber.shade50, borderRadius: BorderRadius.circular(10)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(restaurant.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ]),
                    ),
                  ]),
                  if (restaurant.description != null) ...[
                    const SizedBox(height: 8),
                    Text(restaurant.description!,
                        style: TextStyle(color: Colors.grey[600], height: 1.5)),
                  ],
                  if (restaurant.address != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(restaurant.address!,
                          style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                    ]),
                  ],
                  const Divider(height: 28),
                  const Text('Menü', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),

            // Restorana ait menü ürünlerinin listelendiği kaydırılabilir (SliverList) alan.
            menuAsync.when(
              loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator())),
              error: (e, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Menü yüklenemedi: $e'))),
              data: (items) => items.isEmpty
                  ? const SliverToBoxAdapter(
                  child: Center(child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Henüz ürün eklenmemiş'),
                  )))
                  : SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (_, i) => _MenuItemCard(item: items[i]),
                    childCount: items.length,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Sepette en az bir ürün varsa ekranın en altında sabit olarak gösterilen 'Sepete Git' butonu.
      bottomNavigationBar: cartCount > 0
          ? SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => context.go('/cart'),
            icon: const Icon(Icons.shopping_cart),
            label: Text('Sepete Git ($cartCount ürün)'),
          ),
        ),
      )
          : null,
    );
  }
}

/**
 * Menü listesindeki her bir yiyecek/içecek kaleminin görünümünü ve sepet kontrollerini
 * (artırma/azaltma) yöneten kart bileşeni.
 */
class _MenuItemCard extends ConsumerWidget {
  final MenuItemModel item;
  const _MenuItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // İlgili ürünün sepette kaç adet bulunduğunu anlık olarak çeker.
    final qty              = ref.watch(cartProvider.notifier).quantityOf(item.id);
    final cartRestaurantId = ref.watch(cartRestaurantIdProvider);

    // Farklı restoranlardan aynı sepete ürün eklenmesini engellemek için kontrol bayrağı.
    final blocked          = cartRestaurantId != null &&
        cartRestaurantId != item.restaurantId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        // Ürün Görseli Alanı
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: item.imageUrl != null
              ? Image.network(item.imageUrl!,
              width: 80, height: 80, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _imgPlaceholder())
              : _imgPlaceholder(),
        ),
        const SizedBox(width: 12),

        // Ürün Adı, Açıklaması ve Fiyat Bilgisi
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.name,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          if (item.description != null) ...[
            const SizedBox(height: 4),
            Text(item.description!,
                maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
          const SizedBox(height: 8),
          Text('₺${item.price.toStringAsFixed(2)}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              )),
        ])),

        // Sepet Kontrol (Adet Ekleme/Çıkarma) Mekanizması
        if (blocked)
        // Sepette başka restoranın ürünü varsa bu restoranın ürünleri kilitlenir.
          Tooltip(
            message: 'Sepetinizde başka restoran ürünü var',
            child: Icon(Icons.block, color: Colors.grey[400]),
          )
        else if (qty == 0)
        // Ürün sepette hiç yoksa ilk kez eklemek için '+' butonu gösterilir.
          GestureDetector(
            onTap: () => ref.read(cartProvider.notifier).add(item),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
          )
        else
        // Ürün sepette zaten varsa artırma ve azaltma butonları (Counter) gösterilir.
          Row(mainAxisSize: MainAxisSize.min, children: [
            _CounterBtn(
              icon: Icons.remove,
              onTap: () => ref.read(cartProvider.notifier).remove(item.id),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text('$qty',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            _CounterBtn(
              icon: Icons.add,
              onTap: () => ref.read(cartProvider.notifier).add(item),
            ),
          ]),
      ]),
    );
  }

  /**
   * Ürün görseli yüklenemezse veya boşsa gösterilecek varsayılan yer tutucu bileşen.
   */
  Widget _imgPlaceholder() => Container(
    width: 80, height: 80, color: Colors.grey[100],
    child: const Icon(Icons.fastfood, color: Colors.grey),
  );
}

/**
 * Miktar kontrolü (artı ve eksi) için tasarlanmış küçük kare ikon butonu.
 */
class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CounterBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: AppTheme.primaryColor, size: 18),
    ),
  );
}