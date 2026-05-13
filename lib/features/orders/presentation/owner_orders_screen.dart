import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_theme.dart';
import '../data/order_repository.dart';

/**
 * Restoran sahipleri için, sadece kendi restoranlarına yönlendirilmiş
 * sipariş verilerini asenkron olarak çeken Riverpod sağlayıcısıdır.
 */
final ownerOrdersProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.watch(orderRepositoryProvider).getRestaurantOrders();
});

/**
 * Restoran sahibinin kendi dükkanına düşen aktif siparişleri listelediği
 * ve bu siparişlerin durumunu güncelleyebildiği yönetim ekranı bileşeni.
 */
class OwnerOrdersScreen extends ConsumerWidget {
  const OwnerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // İşletmeye ait sipariş verileri dinlenir.
    final ordersAsync = ref.watch(ownerOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Gelen Siparişler', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (e, _) => Center(child: Text('Hata oluştu: $e')),
        data: (orders) {
          // Gelen hiç sipariş yoksa kullanıcıyı bilgilendiren ekran yapısı.
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Henüz sipariş gelmedi.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          // Sipariş listesi mevcut ise, kullanıcı kaydırarak yenileme (Pull to Refresh)
          // yapabileceği şekilde veriler ekrana listelenir.
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ownerOrdersProvider),
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];

                // Veri güvenliği sağlamak adına eksik (null) gelebilecek alanlar varsayılan değerlerle atanır.
                final int orderId = order['id'] ?? 0;
                final String status = order['status']?.toString() ?? 'hazirlaniyor';
                final String customerName = order['customer_name']?.toString() ?? 'Bilinmiyor';
                final String totalPrice = order['total_price']?.toString() ?? '0.0';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Sipariş başlığı ve durum etiketinin bulunduğu bölüm.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Sipariş #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            _StatusBadge(status: status),
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text('Müşteri: $customerName', style: const TextStyle(fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.payment, size: 20, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Text('Tutar: ₺$totalPrice', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Ekran boyutuna göre butonların alt alta geçmesini destekleyen
                        // duyarlı (responsive) sarıcı (Wrap) bileşeni kullanılmıştır.
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.end,
                          children: [
                            if (status == 'hazirlaniyor')
                              ElevatedButton.icon(
                                onPressed: () => _update(context, ref, orderId, 'yolda'),
                                icon: const Icon(Icons.delivery_dining, size: 18),
                                label: const Text('Yola Çıkar'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            if (status == 'yolda')
                              ElevatedButton.icon(
                                onPressed: () => _update(context, ref, orderId, 'teslim_edildi'),
                                icon: const Icon(Icons.check_circle_outline, size: 18),
                                label: const Text('Teslim Edildi'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  /**
   * Siparişin durumunu backend'e ileterek güncelleyen asenkron fonksiyon.
   * Güncelleme sonrasında arayüzün yenilenmesi için sağlayıcıyı (provider) sıfırlar.
   */
  void _update(BuildContext context, WidgetRef ref, int id, String status) async {
    try {
      await ref.read(orderRepositoryProvider).updateOrderStatus(id, status);
      ref.invalidate(ownerOrdersProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red));
      }
    }
  }
}

/**
 * Siparişin o anki durumunu görsel bir rozet (badge) formatında
 * ekranda gösteren küçük bileşen.
 */
class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.orange;
    String text = 'HAZIRLANIYOR';

    if (status == 'yolda') {
      color = Colors.blue;
      text = 'YOLDA';
    } else if (status == 'teslim_edildi') {
      color = Colors.green;
      text = 'TESLİM EDİLDİ';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}