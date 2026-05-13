import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_theme.dart';
import '../data/order_repository.dart';

/**
 * Müşterinin (Customer) kendi vermiş olduğu geçmiş siparişlerin
 * listelendiği ana ekran bileşenidir.
 */
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Backend'den kullanıcının sipariş verilerini asenkron olarak dinler.
    final ordersAsync = ref.watch(myOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Siparişlerim', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Sayfayı manuel olarak yenilemek için kullanılan buton.
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(myOrdersProvider),
          ),
        ],
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text('$e', textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            TextButton(
              onPressed: () => ref.invalidate(myOrdersProvider),
              child: const Text('Tekrar dene'),
            ),
          ]),
        ),
        data: (orders) => orders.isEmpty
        // Kullanıcının hiç siparişi yoksa gösterilecek yönlendirme alanı.
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Henüz sipariş vermediniz',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.go('/restaurants'),
            child: const Text('Sipariş ver'),
          ),
        ]))
        // Siparişler mevcutsa liste görünümünde ekrana çizilir.
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (_, i) => _OrderTile(order: orders[i]),
        ),
      ),
    );
  }
}

/**
 * Listedeki her bir siparişin özet görünümünü (tarih, tutar, durum)
 * temsil eden özelleştirilmiş kart bileşeni.
 */
class _OrderTile extends StatelessWidget {
  final Map<String, dynamic> order;
  const _OrderTile({required this.order});

  /**
   * Siparişin durumuna göre arayüzde kullanılacak dinamik rengi belirler.
   */
  Color get _statusColor {
    switch (order['status']) {
      case 'hazirlaniyor': return Colors.orange;
      case 'yolda':        return Colors.blue;
      case 'teslim_edildi': return Colors.green;
      default: return Colors.grey;
    }
  }

  /**
   * Siparişin durumuna göre gösterilecek okunabilir Türkçe etiketi belirler.
   */
  String get _statusLabel {
    switch (order['status']) {
      case 'hazirlaniyor': return '🍳 Hazırlanıyor';
      case 'yolda':        return '🛵 Yolda';
      case 'teslim_edildi': return '✅ Teslim Edildi';
      default: return order['status'];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Backend'den gelen tarihi okunabilir yerel formata çevirir.
    final date = DateTime.tryParse(order['created_at'] ?? '');
    final formatted = date != null
        ? DateFormat('dd MMM yyyy, HH:mm', 'tr').format(date)
        : '';

    return GestureDetector(
      // Kartın üzerine tıklandığında ilgili siparişin detay ekranına yönlendirir.
      onTap: () => context.go('/orders/${order['id']}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(order['restaurant_name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_statusLabel,
                  style: TextStyle(color: _statusColor,
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ]),
          const SizedBox(height: 6),
          Text('#${order['id']} • $formatted',
              style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          const Divider(height: 16),
          Row(children: [
            Text('${(order['items'] as List?)?.length ?? 0} ürün',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const Spacer(),
            Text('₺${(order['total_price'] as num).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold,
                    fontSize: 16, color: AppTheme.primaryColor)),
          ]),
        ]),
      ),
    );
  }
}