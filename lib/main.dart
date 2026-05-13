import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_theme.dart';
import 'core/router/app_router.dart';
import 'package:intl/date_symbol_data_local.dart';

/**
 * Uygulamanın başlatıldığı ana (entry point) fonksiyondur.
 * Gerekli Flutter motoru bağlantılarını ve yerelleştirme (dil) ayarlarını
 * yapılandırarak uygulamayı Riverpod ortamında çalıştırır.
 */
void main() async {
  // Asenkron başlatma işlemleri için Flutter platform bağlamlarının hazır olduğundan emin olunur.
  WidgetsFlutterBinding.ensureInitialized();

  // Tarih ve saat formatlarının uygulama genelinde Türkçe (tr_TR) kurallarına
  // uygun olarak gösterilebilmesi için yerel format verilerini yükler.
  await initializeDateFormatting('tr_TR', null);

  // Uygulamayı global durum yönetimi (State Management) için ProviderScope ile sarmalayarak başlatır.
  runApp(const ProviderScope(child: App()));
}

/**
 * Uygulamanın kök (root) bileşenidir.
 * Tema yapılandırmasını (AppTheme) ve GoRouter tabanlı navigasyon altyapısını sisteme entegre eder.
 */
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Riverpod üzerinden sağlanan yönlendirme (router) kurallarını ve güncel rotayı dinler.
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Yemek Sipariş',
      // Uygulama genelinde kullanılacak aydınlık (light) tema şablonunu belirler.
      theme: AppTheme.light,
      // Navigasyon işlemlerinin (sayfa geçişleri, guard kontrolleri) GoRouter tarafından yönetilmesini sağlar.
      routerConfig: router,
      // Sağ üst köşedeki geliştirme (debug) etiketini gizler.
      debugShowCheckedModeBanner: false,
    );
  }
}