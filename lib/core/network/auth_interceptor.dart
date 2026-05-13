import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/presentation/auth_provider.dart';

/**
 * Uygulamadan çıkan tüm HTTP isteklerinin arasına giren (intercept eden) özel kimlik doğrulama katmanı.
 * Token ekleme ve yetki düşme (Unauthorized) durumlarını merkezi olarak otomatik yönetir.
 */
class AuthInterceptor extends Interceptor {
  final Ref ref;
  final SecureStorage _secureStorage = SecureStorage();

  AuthInterceptor(this.ref);

  /**
   * İstek sunucuya gönderilmeden hemen önce tetiklenen fonksiyondur.
   * Cihazın güvenli deposundan (Secure Storage) kayıtlı kullanıcı token'ını alır ve giden isteğin başlığına (Header) 'Bearer' formatında güvenli bir şekilde ekler.
   */
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _secureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    super.onRequest(options, handler);
  }

  /**
   * Sunucudan olumsuz bir hata yanıtı döndüğünde tetiklenen fonksiyondur.
   * Eğer API 401 (Unauthorized - Yetkisiz) hatası döndürürse, bu durum kullanıcının token süresinin dolduğunu veya geçersiz olduğunu belirtir.
   * Bu senaryoda kullanıcı otomatik olarak sistemden çıkarılır (logout) ve güvenliği sağlamak için giriş ekranına yönlendirilir.
   */
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      ref.read(authProvider.notifier).logout();
    }
    super.onError(err, handler);
  }
}