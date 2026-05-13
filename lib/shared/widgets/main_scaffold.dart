import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/**
 * Uygulamanın müşteri (Customer) tarafındaki temel iskeletini (Scaffold) oluşturur.
 * Alt gezinme çubuğunu (Bottom Navigation Bar) barındırarak ana sekmeler arası
 * geçişin yönetilmesini sağlar.
 */
class MainScaffold extends StatelessWidget {
  final Widget child;
  const MainScaffold({super.key, required this.child});

  /**
   * GoRouter'ın mevcut URL konumunu okuyarak, alt gezinme çubuğunda
   * hangi sekmenin aktif (seçili) olarak gösterileceğini hesaplar.
   */
  int _currentIndex(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    if (loc.startsWith('/restaurants')) return 0;
    if (loc.startsWith('/cart'))        return 1;
    if (loc.startsWith('/orders'))      return 2;
    if (loc.startsWith('/profile'))     return 3;
    return 0; // Varsayılan olarak Restoranlar sekmesini aktif kabul eder.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Yönlendirmelere göre değişen aktif sayfa içeriği
      body: child,
      // Ana sekmeler arası geçişi sağlayan Material 3 tasarımlı alt navigasyon çubuğu.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex(context),
        onDestinationSelected: (i) {
          // Kullanıcının dokunduğu ikona göre ilgili ana rotaya yönlendirme yapar.
          switch (i) {
            case 0: context.go('/restaurants'); break;
            case 1: context.go('/cart');        break;
            case 2: context.go('/orders');      break;
            case 3: context.go('/profile');     break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant_menu), label: 'Restoranlar'),
          NavigationDestination(icon: Icon(Icons.shopping_cart),   label: 'Sepet'),
          NavigationDestination(icon: Icon(Icons.receipt_long),    label: 'Siparişler'),
          NavigationDestination(icon: Icon(Icons.person),          label: 'Profil'),
        ],
      ),
    );
  }
}