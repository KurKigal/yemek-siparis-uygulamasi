import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../domain/user_model.dart';

/**
 * AuthRepository sınıfını uygulama genelinde erişilebilir kılan Riverpod sağlayıcısı.
 * Bağımlılıkları (Dio ve SecureStorage) otomatik olarak enjekte eder.
 */
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = SecureStorage();
  return AuthRepository(dio, storage);
});

/**
 * Kullanıcı kimlik doğrulama süreçlerinin (Giriş, Kayıt, Çıkış, Şifre Değiştirme)
 * API üzerinden yönetimini sağlayan veri erişim (Repository) katmanı.
 */
class AuthRepository {
  final Dio _dio;
  final SecureStorage _storage;

  AuthRepository(this._dio, this._storage);

  /**
   * Kullanıcının e-posta ve şifresi ile sisteme giriş yapmasını sağlar.
   * Başarılı olursa dönen token'ı cihaza kaydeder ve kullanıcı modelini döndürür.
   */
  Future<UserModel> login(String email, String password) async {
    try {
      final res = await _dio.post(ApiConstants.login, data: {
        'email': email,
        'password': password,
      });
      await _storage.saveToken(res.data['token']);
      return UserModel.fromJson(res.data['user']);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Giriş yapılamadı';
    }
  }

  /**
   * Sisteme yeni bir kullanıcı veya restoran sahibi kaydeder.
   * Başarılı kayıt sonrası token'ı cihaza kaydeder ve otomatik giriş yaptırır.
   */
  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String role = 'customer',
  }) async {
    try {
      final res = await _dio.post(ApiConstants.register, data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      });
      await _storage.saveToken(res.data['token']);
      return UserModel.fromJson(res.data['user']);
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Kayıt işlemi başarısız';
    }
  }

  /**
   * Cihazda kayıtlı olan token'ı kullanarak backend'den mevcut kullanıcı bilgilerini çeker.
   * Token geçersizse veya süresi dolmuşsa otomatik olarak çıkış işlemini tetikler.
   */
  Future<UserModel?> getMe() async {
    try {
      final token = await _storage.getToken();
      if (token == null) return null;

      final res = await _dio.get(ApiConstants.me);
      return UserModel.fromJson(res.data['user'] ?? res.data);
    } catch (e) {
      await logout();
      return null;
    }
  }

  /**
   * Cihazda saklanan yetkilendirme token'ını silerek kullanıcının oturumunu kapatır.
   */
  Future<void> logout() async {
    await _storage.deleteToken();
  }

  /**
   * Kullanıcının mevcut şifresini kontrol ederek yeni bir şifre belirlemesine olanak tanır.
   */
  Future<void> changePassword(String oldPassword, String newPassword) async {
    try {
      await _dio.post(ApiConstants.changePassword, data: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      });
    } on DioException catch (e) {
      throw e.response?.data['message'] ?? 'Şifre değiştirilemedi.';
    }
  }
}