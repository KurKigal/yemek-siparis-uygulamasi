import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

/**
 * Uygulama genelinde kullanılacak olan merkezi HTTP istemcisini (Dio) oluşturan Riverpod sağlayıcısı.
 * Tüm backend (API) istekleri bu yapılandırılmış temel istemci üzerinden gerçekleştirilir.
 */
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  // Giden her isteğe otomatik olarak yetkilendirme (Token) başlığı ekleyen ve hataları yakalayan güvenlik katmanı.
  dio.interceptors.add(AuthInterceptor(ref));

  // Geliştirme ve hata ayıklama (debug) sürecini kolaylaştırmak amacıyla, atılan isteklerin ve gelen yanıtların detaylarını konsola yazdıran loglama katmanı.
  dio.interceptors.add(LogInterceptor(responseBody: true, requestBody: true));

  return dio;
});