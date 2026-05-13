import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/auth/presentation/auth_provider.dart';

/**
 * Kullanıcının kimlik doğrulama (auth) durumunu dinleyen ve herhangi bir
 * değişiklikte GoRouter'ı tetikleyerek sayfa yönlendirmelerini güncelleyen sınıf.
 */
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Uygulama genelindeki kimlik doğrulama sağlayıcısını (authProvider) dinler.
    // Kullanıcı giriş veya çıkış yaptığında notifyListeners() metodunu çağırarak
    // router sistemini (GoRouter'ın refreshListenable mekanizmasını) uyarır.
    _ref.listen<AsyncValue<UserModel?>>(
      authProvider,
          (_, __) => notifyListeners(),
    );
  }

  // Sistemde oturum açmış aktif bir kullanıcı olup olmadığını doğrular.
  bool get isLoggedIn => _ref.read(authProvider).value != null;

  // Kimlik doğrulama veya veri çekme işlemlerinin halen devam edip etmediğini kontrol eder.
  bool get isLoading  => _ref.read(authProvider).isLoading;

  // Mevcut kullanıcının sistemdeki rolünü (customer, restaurant_owner veya admin) getirir.
  String? get userRole => _ref.read(authProvider).valueOrNull?.role;
}

/**
 * RouterNotifier sınıfını uygulama genelinde erişilebilir hale getiren Riverpod sağlayıcısı.
 */
final routerNotifierProvider = Provider<RouterNotifier>(
      (ref) => RouterNotifier(ref),
);