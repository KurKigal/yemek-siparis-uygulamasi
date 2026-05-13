import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../orders/data/order_repository.dart';
import '../data/payment_repository.dart';
import '../../../core/constants/app_theme.dart';
import '../../../shared/widgets/loading_button.dart';

/**
 * Oluşturulan bir siparişin ödemesinin alınması adımını simüle eden arayüz bileşeni.
 * URL üzerinden sipariş ID'sini ve ödenecek miktarı parametre olarak alır.
 */
class PaymentScreen extends ConsumerStatefulWidget {
  final int orderId;
  final double totalAmount;

  const PaymentScreen({
    super.key,
    required this.orderId,
    required this.totalAmount
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  late TextEditingController _amountCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Ekran açıldığında siparişin gerçek fiyatı metin alanına otomatik doldurulur.
    _amountCtrl = TextEditingController(text: widget.totalAmount.toString());
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  /**
   * Girilen ödeme miktarını alıp API üzerinden ödeme işlemi simülasyonunu başlatır.
   * İşlem başarılı olursa veya hata fırlatılırsa kullanıcıya sonuç popup'ı (dialog) gösterir.
   */
  Future<void> _handlePayment() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (amount == null || amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final message = await ref.read(paymentRepositoryProvider).pay(widget.orderId, amount);

      if (!mounted) return;
      setState(() => _isLoading = false);

      _showResultDialog(title: 'İşlem Başarılı', message: message, isSuccess: true);

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      _showResultDialog(title: 'Ödeme Reddedildi', message: e.toString(), isSuccess: false);
    }
  }

  /**
   * Ödeme durumunun sonucunu (başarılı/başarısız) ekranda görsel bir diyalog
   * penceresi aracılığıyla kullanıcıya bildirir. İşlem başarılı ise siparişler
   * listesini yenileyerek sayfaya yönlendirme yapar.
   */
  void _showResultDialog({required String title, required String message, required bool isSuccess}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(
          isSuccess ? Icons.check_circle_outline : Icons.error_outline,
          color: isSuccess ? Colors.green : Colors.red,
          size: 60,
        ),
        title: Text(title, textAlign: TextAlign.center),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (isSuccess) {
                // Siparişler sayfasındaki verilerin en güncel halini alabilmesi için provider sıfırlanır.
                ref.invalidate(myOrdersProvider);
                context.go('/orders');
              }
            },
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ödeme Simülasyonu')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.credit_card, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            const Text(
              'Ödenecek Tutarı Onaylayın',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Test için tutarı değiştirebilirsiniz.\n1000 TL üzeri miktarlar reddedilecektir.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Ödeme Miktarı (₺)',
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const Spacer(),
            LoadingButton(
              text: 'Ödemeyi Tamamla',
              isLoading: _isLoading,
              onPressed: _handlePayment,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}