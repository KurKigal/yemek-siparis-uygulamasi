import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/admin/presentation/admin_dashboard_screen.dart';
import '../../features/menu/presentation/owner_menu_screen.dart';
import '../../features/orders/presentation/owner_orders_screen.dart';
import 'router_notifier.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/restaurants/presentation/restaurant_list_screen.dart';
import '../../features/restaurants/presentation/restaurant_detail_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/cart/presentation/payment_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../shared/widgets/main_scaffold.dart';
import '../../shared/widgets/owner_scaffold.dart';

/**
 * Uygulamanın yönlendirme (routing) ağacını ve rol bazlı güvenlik kurallarını
 * merkezi olarak yöneten Riverpod sağlayıcısı.
 */
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/restaurants',
    refreshListenable: notifier,

    /**
     * Kullanıcının oturum ve rol durumuna göre sayfa erişimlerini denetleyen,
     * yetkisiz erişimleri engelleyen yönlendirme (Guard) mekanizması.
     */
    redirect: (context, state) {
      if (notifier.isLoading) return null;

      final isLoggedIn  = notifier.isLoggedIn;
      final role        = notifier.userRole;
      final loc         = state.uri.path;
      final isAuthRoute = loc == '/login' || loc == '/register';

      // Oturum açmamış kullanıcıları zorunlu olarak giriş ekranına yönlendirir.
      if (!isLoggedIn && !isAuthRoute) return '/login';

      // Zaten oturum açmış kullanıcıların giriş/kayıt sayfalarına gitmesini engeller ve
      // sahip oldukları role uygun ana kontrol panellerine yönlendirir.
      if (isLoggedIn && isAuthRoute) {
        if (role == 'restaurant_owner') return '/owner/orders';
        if (role == 'admin') return '/admin/dashboard';
        return '/restaurants';
      }

      // Rol Bazlı Güvenlik Duvarı (Role Guard): Kullanıcıların yetkisi olmayan
      // panellere doğrudan URL üzerinden veya yanlışlıkla erişmesini engeller.
      if (isLoggedIn) {
        final isOwnerRoute = loc.startsWith('/owner');
        final isCustomerRoute = loc.startsWith('/restaurants') || loc.startsWith('/cart');

        if (role == 'restaurant_owner' && isCustomerRoute) return '/owner/orders';
        if (role == 'customer' && isOwnerRoute) return '/restaurants';
      }

      // Herhangi bir güvenlik veya iş kuralı ihlali yoksa erişime izin verir.
      return null;
    },
    routes: [
      // Kimlik doğrulama süreçlerinin yürütüldüğü rotalar.
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),

      // Ödeme simülasyonu ekranı. Rota parametresi olarak sipariş ID'sini,
      // Query parametresi olarak da ödenecek toplam miktarı alır.
      GoRoute(
        path: '/payment/:id',
        builder: (context, state) {
          final id = int.parse(state.pathParameters['id']!);
          final amount = double.tryParse(state.uri.queryParameters['amount'] ?? '0') ?? 0.0;
          return PaymentScreen(
            orderId: id,
            totalAmount: amount,
          );
        },
      ),

      // Müşteri (Customer) rolündeki kullanıcıların alt gezinme çubuğu (Bottom Navigation Bar)
      // ile erişebildiği standart sayfaları kapsayan ana yapı.
      ShellRoute(
        builder: (context, state, child) => MainScaffold(child: child),
        routes: [
          GoRoute(
            path: '/restaurants',
            builder: (_, __) => const RestaurantListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => RestaurantDetailScreen(
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
          GoRoute(
            path: '/orders',
            builder: (_, __) => const OrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => OrderDetailScreen(
                  id: int.parse(state.pathParameters['id']!),
                ),
              ),
            ],
          ),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Restoran Sahibi (Owner) rolündeki kullanıcılara özel yönetim menülerini
      // barındıran alt gezinme yapısı.
      ShellRoute(
        builder: (context, state, child) => OwnerScaffold(child: child),
        routes: [
          GoRoute(
            path: '/owner/orders',
            builder: (_, __) => const OwnerOrdersScreen(),
          ),
          GoRoute(
            path: '/owner/menu',
            builder: (_, __) => const OwnerMenuScreen(),
          ),
          GoRoute(
            path: '/owner/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
        ],
      ),

      // Sistem yöneticisinin (Admin) tüm restoranları yönettiği tek sayfalık genel kontrol paneli.
      GoRoute(
        path: '/admin/dashboard',
        builder: (_, __) => const AdminDashboardScreen(),
      ),
    ],
  );
});