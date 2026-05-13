/**
 * Uygulamanın backend (sunucu) ile iletişim kurarken kullanacağı temel URL
 * ve API uç noktalarını (endpoint) barındıran sabitler sınıfı.
 */
class ApiConstants {
  // Uygulamanın çalıştığı ortama göre (Android, iOS, Web) backend ana dizini
  static const String baseUrl = 'http://10.0.2.2:3000/api';

  // Kimlik doğrulama ve kullanıcı yönetimi uç noktaları
  static const String register  = '/auth/register';
  static const String login     = '/auth/login';
  static const String me        = '/auth/me';
  static const String profile   = '/auth/profile';
  static const String changePassword = '/auth/change-password';

  // İş modeli (Domain) uç noktaları
  static const String restaurants = '/restaurants';
  static const String menu      = '/menu';
  static const String orders    = '/orders';
  static const String payment   = '/payment';
}