import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../features/cart/presentation/cart_provider.dart';
import 'restaurant_provider.dart';
import '../domain/restaurant_model.dart';

/**
 * Kullanıcının arama çubuğuna girdiği metni ve seçtiği filtreleme kategorisini
 * hafızada tutan lokal durum (state) sağlayıcıları.
 */
final _searchQueryProvider = StateProvider<String?>((ref) => null);
final _selectedCategoryProvider = StateProvider<String>((ref) => 'Tümü');

/**
 * Müşterilerin sisteme kayıtlı tüm restoranları listeleyebildiği, arama yapabildiği
 * ve kategorilere göre filtreleyebildiği uygulamanın ana giriş ekranıdır.
 */
class RestaurantListScreen extends ConsumerWidget {
  const RestaurantListScreen({super.key});

  // Kullanıcıların yatay kaydırarak seçebileceği mutfak/kategori filtreleri.
  final List<String> categories = const ['Tümü', 'Burger', 'Pizza', 'Kebap', 'Tatlı', 'Ev Yemekleri'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query            = ref.watch(_searchQueryProvider);
    final selectedCategory = ref.watch(_selectedCategoryProvider);
    final listAsync        = ref.watch(restaurantListProvider(query));
    final cartCount        = ref.watch(cartCountProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Restoranlar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          // Sepet İkonu ve Bildirim Rozeti (Badge)
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.black87),
                onPressed: () => context.go('/cart'),
              ),
              if (cartCount > 0)
                Positioned(
                  right: 6, top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$cartCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(children: [

        // Kullanıcının metin girerek restoran araması yapmasını sağlayan arama çubuğu alanı.
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Restoran veya mutfak ara...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              suffixIcon: query != null
                  ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => ref.read(_searchQueryProvider.notifier).state = null,
              )
                  : null,
            ),
            onChanged: (v) => ref.read(_searchQueryProvider.notifier).state =
            v.trim().isEmpty ? null : v.trim(),
          ),
        ),

        // Restoranları türlerine göre (Pizza, Burger vb.) filtrelemeye yarayan yatay çip (ChoiceChip) listesi.
        Container(
          color: Colors.white,
          padding: const EdgeInsets.only(bottom: 12),
          child: SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    side: BorderSide.none,
                    onSelected: (_) {
                      ref.read(_selectedCategoryProvider.notifier).state = category;
                    },
                  ),
                );
              },
            ),
          ),
        ),

        // Filtrelenen veya direkt çekilen restoran verilerinin ekranda listelendiği ana alan.
        Expanded(
          child: listAsync.when(
            loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            error: (e, _) => Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text('Bağlantı hatası', style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => ref.invalidate(restaurantListProvider(query)),
                  child: const Text('Tekrar dene'),
                ),
              ]),
            ),
            data: (list) {
              // API'den gelen listeyi, kullanıcının seçtiği kategoriye göre uygulama tarafında (Client-Side) filtreler.
              final filteredList = list.where((r) {
                if (selectedCategory == 'Tümü') return true;

                final matchesName = r.name.toLowerCase().contains(selectedCategory.toLowerCase());
                final matchesDesc = r.description != null && r.description!.toLowerCase().contains(selectedCategory.toLowerCase());

                return matchesName || matchesDesc;
              }).toList();

              // Seçilen kategoride restoran yoksa kullanıcıya geri bildirim ekranı sunar.
              if (filteredList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('Bu kategoride restoran bulunamadı', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              // Filtreleri geçen restoranları dikey bir liste halinde arayüze çizer.
              return RefreshIndicator(
                onRefresh: () => ref.refresh(restaurantListProvider(query).future),
                color: AppTheme.primaryColor,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredList.length,
                  itemBuilder: (_, i) => _RestaurantCard(restaurant: filteredList[i]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

/**
 * Listede yer alan her bir restoranın kapak fotoğrafı, adı, puanı ve adresi gibi
 * özet bilgilerini şık bir tasarımla sunan kart bileşenidir. Tıklanıldığında detay sayfasına yönlendirir.
 */
class _RestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/restaurants/${restaurant.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Restoran Kapak Görseli
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: restaurant.logoUrl != null
                ? Image.network(restaurant.logoUrl!,
                height: 160, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          // Restoran Detayları (Ad, Puan, Açıklama, Adres)
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(restaurant.name,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star, size: 14, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ]),
                ),
              ]),
              if (restaurant.description != null) ...[
                const SizedBox(height: 4),
                Text(restaurant.description!,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
              if (restaurant.address != null) ...[
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.location_on_outlined, size: 13, color: Colors.grey[500]),
                  const SizedBox(width: 2),
                  Expanded(child: Text(restaurant.address!,
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12))),
                ]),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  /**
   * Restoran görseli yüklenemezse gösterilecek varsayılan yer tutucu ikon kutusu.
   */
  Widget _placeholder() => Container(
    height: 160, color: Colors.grey[100],
    child: const Center(child: Icon(Icons.restaurant, size: 48, color: Colors.grey)),
  );
}