import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

/**
 * Uygulama genelinde kullanıcının kimlik doğrulama (auth) durumunu yöneten merkezi AsyncNotifier.
 * Yüklenme (loading), başarılı veri (data) ve hata (error) durumlarını izler.
 */
class AuthNotifier extends AsyncNotifier<UserModel?> {
  late AuthRepository _repo;

  /**
   * Sağlayıcı ilk oluşturulduğunda çalışır. Repository'yi dinlemeye başlar
   * ve cihazdaki mevcut token ile kullanıcının oturumunu geri yüklemeyi (otomatik girişi) dener.
   */
  @override
  Future<UserModel?> build() async {
    _repo = ref.watch(authRepositoryProvider);
    return await _repo.getMe();
  }

  /**
   * Kullanıcı giriş isteğini işler. İşlem süresince UI'ı bilgilendirmek için
   * durumu önce yükleniyor'a (AsyncLoading) çeker.
   */
  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repo.login(email, password));
  }

  /**
   * Yeni kullanıcı kaydı isteğini gerçekleştirir. Rol parametresi ile
   * kullanıcının yetki sınırlarını belirler.
   */
  Future<void> register({
    required String name,
    required String email,
    required String password,
    String role = 'customer',
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
          () => _repo.register(name: name, email: email, password: password, role: role),
    );
  }

  /**
   * Oturumu kapatır, cihazdaki kayıtlı token'ı temizler ve uygulamayı çıkış yapmış (null) duruma getirir.
   */
  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }

  /**
   * Mevcut şifreyi doğrulayarak kullanıcının yeni bir şifre belirlemesini sağlar.
   */
  Future<void> changePassword(String oldPassword, String newPassword) async {
    await _repo.changePassword(oldPassword, newPassword);
  }
}

/**
 * Arayüz bileşenlerinin auth durumunu (yüklenme, hata, veri) dinleyebilmesi için oluşturulan sağlayıcı.
 */
final authProvider = AsyncNotifierProvider<AuthNotifier, UserModel?>(AuthNotifier.new);

/**
 * Kullanıcı modeline (isim, rol, e-posta) uygulama içerisinden kolayca ve hızlıca erişebilmek için
 * authProvider içindeki güncel veriyi süzüp döndüren yardımcı sağlayıcı.
 */
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authProvider).value;
});