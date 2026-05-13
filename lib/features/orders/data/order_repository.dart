import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart'; // API uç noktaları için sabitler.
import '../../../core/network/dio_client.dart'; // Merkezi HTTP istemcisi.

/**
 * Sipariş operasyonlarının (Listeleme, Detay Görüntüleme, Durum Güncelleme)
 * backend ile haberleşmesini yöneten veri erişim katmanıdır.
 */
class OrderRepository {
  final Dio _dio;
  OrderRepository(this._dio);

  /**
   * Giriş yapmış olan müşterinin geçmişte verdiği tüm siparişleri listeler.
   */
  Future<List<dynamic>> getMyOrders() async {
    final res = await _dio.get(ApiConstants.orders);
    return res.data as List;
  }

  /**
   * Kimlik numarası (id) verilen spesifik bir siparişin
   * ürünlerini ve tüm detay bilgilerini getirir.
   */
  Future<Map<String, dynamic>> getOrderDetail(int id) async {
    final res = await _dio.get('${ApiConstants.orders}/$id');
    return res.data;
  }

  /**
   * Restoran sahibinin kendi dükkanına gelen siparişleri
   * görüntüleyebilmesi için kullanılan metoddur.
   */
  Future<List<dynamic>> getRestaurantOrders() async {
    final res = await _dio.get('${ApiConstants.orders}/owner');
    return res.data;
  }

  /**
   * Bir siparişin operasyonel durumunu (hazırlanıyor, yolda, teslim edildi vb.)
   * güncellemek için kullanılır.
   */
  Future<void> updateOrderStatus(int id, String status) async {
    await _dio.put('${ApiConstants.orders}/$id/status', data: {'status': status});
  }
}

/**
 * OrderRepository sınıfına uygulama genelinde erişimi sağlayan Riverpod sağlayıcısıdır.
 * Bağımlılık olarak yapılandırılmış Dio istemcisini kullanır.
 */
final orderRepositoryProvider = Provider<OrderRepository>(
      (ref) => OrderRepository(ref.read(dioProvider)),
);

/**
 * Kullanıcının siparişlerini asenkron olarak çeken ve UI tarafında
 * kolayca dinlenmesini sağlayan sağlayıcıdır.
 */
final myOrdersProvider = FutureProvider<List<dynamic>>(
      (ref) => ref.read(orderRepositoryProvider).getMyOrders(),
);