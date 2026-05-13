import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';

/**
 * Ödeme süreçlerinin API iletişimini soyutlayan, uygulamanın geri kalanına
 * hazır metodlar sunan Riverpod bağımlılık enjeksiyon sağlayıcısı.
 */
final paymentRepositoryProvider = Provider((ref) => PaymentRepository(ref.read(dioProvider)));

/**
 * Ödeme işlemlerinin backend ile haberleşme mantığını (Repository) barındıran veri katmanı.
 */
class PaymentRepository {
  final Dio _dio;
  PaymentRepository(this._dio);

  /**
   * Belirtilen tutarın, ilgili sipariş ID'si kullanılarak ödenmesi için sunucuya istek gönderir.
   */
  Future<String> pay(int orderId, double amount) async {
    try {
      final res = await _dio.post('${ApiConstants.payment}/$orderId', data: {'amount': amount});
      return res.data['message'] ?? 'Ödeme başarılı';
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        throw e.response!.data['message'] ?? 'Ödeme reddedildi.';
      }
      throw 'İnternet bağlantınızı kontrol edin.';
    }
  }
}