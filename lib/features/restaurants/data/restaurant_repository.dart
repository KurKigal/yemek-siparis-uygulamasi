import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../domain/restaurant_model.dart';

/**
 * Restoran verileriyle ilgili backend (API) iletişimini yöneten veri erişim katmanıdır.
 * Uygulamanın restoranları listeleme ve detaylarını getirme gibi işlemlerini soyutlar.
 */
class RestaurantRepository {
  final Dio _dio;
  RestaurantRepository(this._dio);

  /**
   * Sistemdeki aktif restoranların tamamını bir liste halinde getirir.
   * İsteğe bağlı olarak gönderilen 'query' parametresi sayesinde backend üzerinde
   * isim bazlı arama (filtreleme) yapılmasını sağlar.
   */
  Future<List<RestaurantModel>> getAll({String? query}) async {
    final res = await _dio.get(
      ApiConstants.restaurants,
      queryParameters: query != null ? {'q': query} : null,
    );
    // Gelen JSON dizisini dolaşarak her bir elemanı RestaurantModel nesnesine dönüştürür.
    return (res.data as List).map((e) => RestaurantModel.fromJson(e)).toList();
  }

  /**
   * Belirtilen kimlik numarasına (id) sahip spesifik bir restoranın
   * tüm detay bilgilerini backend'den çeker.
   */
  Future<RestaurantModel> getById(int id) async {
    final res = await _dio.get('${ApiConstants.restaurants}/$id');
    return RestaurantModel.fromJson(res.data);
  }
}

/**
 * RestaurantRepository sınıfını uygulama genelinde erişilebilir kılan Riverpod sağlayıcısıdır.
 * API istekleri için yapılandırılmış merkezi 'dioProvider' istemcisini kullanır.
 */
final restaurantRepositoryProvider = Provider<RestaurantRepository>(
      (ref) => RestaurantRepository(ref.read(dioProvider)),
);