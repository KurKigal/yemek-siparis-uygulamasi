import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_theme.dart';

/**
 * Restoran sahibi (Owner) rolündeki kullanıcılar için uygulamanın ana iskeletini (Scaffold)
 * oluşturan ve alt gezinme çubuğunu (Bottom Navigation Bar) yöneten arayüz bileşenidir.
 */
class OwnerScaffold extends StatelessWidget {
  final Widget child;
  const OwnerScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // GoRouter üzerinden uygulamanın o anki aktif URL yolunu (path) alır.
    final String location = GoRouterState.of(context).uri.path;

    /**
     * URL yoluna bakarak alt gezinme çubuğunda (Siparişler, Menüm, Profil)
     * hangi sekmenin aktif (seçili) olarak gösterileceğini hesaplayan yerel fonksiyondur.
     */
    int calculateSelectedIndex() {
      if (location.startsWith('/owner/orders')) return 0;
      if (location.startsWith('/owner/menu')) return 1;
      if (location.startsWith('/owner/profile')) return 2;
      return 0;
    }

    return Scaffold(
      // Seçilen sekmeye ait sayfa içeriği
      body: child,
      // Restoran sahibine özel işlevleri barındıran alt gezinme çubuğu
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: calculateSelectedIndex(),
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          // Tıklanan sekme indeksine göre GoRouter üzerinden ilgili sayfaya yönlendirme yapar
          switch (index) {
            case 0: context.go('/owner/orders'); break;
            case 1: context.go('/owner/menu'); break;
            case 2: context.go('/owner/profile'); break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Siparişler'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menüm'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}