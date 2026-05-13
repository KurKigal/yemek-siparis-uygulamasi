import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../data/order_repository.dart';

/**
 * Belirli bir siparişin detaylarını (içindeki ürünler, tutar vb.) ID
 * bazlı olarak backend'den çeken Family tipi sağlayıcı.
 */
final _orderDetailProvider = FutureProvider.family<Map<String, dynamic>, int>(
      (ref, id) => ref.read(orderRepositoryProvider).getOrderDetail(id),
);

/**
 * Seçilen bir siparişin tüm aşamalarını, adres bilgisini ve alınan
 * ürünlerin listesini gösteren detay ekranı bileşeni.
 */
class OrderDetailScreen extends ConsumerWidget {
  final int id;
  const OrderDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // İlgili ID'ye sahip sipariş verisi dinlenir.
    final orderAsync = ref.watch(_orderDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => context.pop(),
        ),
        title: Text('Sipariş #$id',
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Hata: $e')),
        data: (order) {
          final items = order['items'] as List? ?? [];
          final date  = DateTime.tryParse(order['created_at'] ?? '');
          final formatted = date != null
              ? DateFormat('dd MMMM yyyy, HH:mm', 'tr').format(date) : '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Siparişin mevcut aşamasını görselleştiren ilerleme çubuğu alanı.
              _StatusCard(status: order['status'] ?? ''),
              const SizedBox(height: 12),

              // Teslimat ve ödeme gibi genel sipariş detaylarının listelendiği kart.
              _InfoCard(children: [
                _InfoRow('Tarih', formatted),
                _InfoRow('Adres', order['address'] ?? '-'),
                _InfoRow('Ödeme',
                    order['payment_status'] == 'odendi' ? '✅ Ödendi' : '⏳ Bekliyor'),
              ]),
              const SizedBox(height: 12),

              // Siparişe dahil olan ürünlerin ve ödenecek toplam tutarın gösterildiği bölüm.
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 6, offset: const Offset(0, 2))],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Ürünler',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const Divider(height: 16),
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      Text('${item['quantity']}x ',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Expanded(child: Text(item['name'] ?? '')),
                      Text('₺${((item['unit_price'] as num) * (item['quantity'] as num)).toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w500)),
                    ]),
                  )),
                  const Divider(height: 16),
                  Row(children: [
                    const Text('Toplam',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    const Spacer(),
                    Text('₺${(order['total_price'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold,
                            fontSize: 18, color: AppTheme.primaryColor)),
                  ]),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

/**
 * Siparişin hangi aşamada olduğunu (Hazırlanıyor, Yolda, Teslim Edildi)
 * çizgiler ve ikonlar yardımıyla dinamik olarak gösteren ilerleme bileşeni.
 */
class _StatusCard extends StatelessWidget {
  final String status;
  const _StatusCard({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = ['hazirlaniyor', 'yolda', 'teslim_edildi'];
    final labels = ['Hazırlanıyor', 'Yolda', 'Teslim Edildi'];
    final icons  = [Icons.restaurant, Icons.delivery_dining, Icons.check_circle];
    final current = steps.indexOf(status);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final filled = (i ~/ 2) < current;
            return Expanded(child: Container(height: 2,
                color: filled ? AppTheme.primaryColor : Colors.grey[200]));
          }
          final idx    = i ~/ 2;
          final active = idx <= current;
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: active ? AppTheme.primaryColor : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(icons[idx],
                  color: active ? Colors.white : Colors.grey, size: 20),
            ),
            const SizedBox(height: 6),
            Text(labels[idx],
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.bold : FontWeight.normal,
                  color: active ? AppTheme.primaryColor : Colors.grey,
                )),
          ]);
        }),
      ),
    );
  }
}

/**
 * Genel bilgi satırlarını düzenli bir kart görünümünde gruplayan sarmalayıcı bileşen.
 */
class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
          blurRadius: 6, offset: const Offset(0, 2))],
    ),
    child: Column(children: children),
  );
}

/**
 * Metinleri sağ-sol hizalı ve okunabilir şekilde gösteren genel bilgi satırı bileşeni.
 */
class _InfoRow extends StatelessWidget {
  final String label, value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(width: 80,
          child: Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 13))),
      Expanded(child: Text(value,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
    ]),
  );
}