import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/**
 * Cihaz hafızasında saklanacak JWT token'ı için benzersiz anahtar kelime.
 */
const _tokenKey = 'auth_token';

/**
 * Kullanıcı kimlik doğrulama verilerini (Token) cihazın şifrelenmiş
 * depolama alanında (iOS Keychain / Android Keystore) güvenli bir şekilde yöneten sınıf.
 */
class SecureStorage {
  final _storage = const FlutterSecureStorage();

  /**
   * Başarılı giriş veya kayıt sonrasında backend'den gelen token'ı güvenli depoya yazar.
   */
  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  /**
   * Cihazda kayıtlı bir token olup olmadığını okur. Oturum kontrolü için kullanılır.
   */
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  /**
   * Kullanıcı çıkış yaptığında (logout) yetkisiz erişimi engellemek için token'ı cihazdan siler.
   */
  Future<void> deleteToken() => _storage.delete(key: _tokenKey);
}

/**
 * Uygulama genelinde SecureStorage sınıfına tek bir noktadan erişimi sağlayan Riverpod sağlayıcısı.
 */
final secureStorageProvider = Provider<SecureStorage>((ref) => SecureStorage());