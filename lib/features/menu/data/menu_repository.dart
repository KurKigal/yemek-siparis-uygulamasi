import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../domain/menu_item_model.dart';

/**
 * Menü öğeleriyle ilgili CRUD (Oluşturma, Okuma, Güncelleme, Silme) işlemlerinin
 * API iletişimini yöneten veri erişim katmanıdır.
 */
class MenuRepository {
  final Dio _dio;
  MenuRepository(this._dio);

  /**
   * Belirli bir restoranın kimlik numarasını kullanarak, o restorana ait
   * aktif tüm menü öğelerini backend'den çeker.
   */
  Future<List<MenuItemModel>> getByRestaurant(int restaurantId) async {
    final res = await _dio.get('${ApiConstants.menu}/$restaurantId');
    // Gelen ham liste verisini haritalayarak MenuItemModel nesnelerinden oluşan bir listeye çevirir.
    return (res.data as List).map((e) => MenuItemModel.fromJson(e)).toList();
  }
}

/**
 * MenuRepository sınıfını uygulama genelinde erişilebilir kılan Riverpod sağlayıcısıdır.
 * 'dioProvider' üzerinden yapılandırılmış HTTP istemcisini kullanır.
 */
final menuRepositoryProvider = Provider<MenuRepository>(
      (ref) => MenuRepository(ref.read(dioProvider)),
);

/**
 * Arayüz tarafında belirli bir restoranın menüsünü asenkron olarak dinlemeyi
 * ve çekmeyi sağlayan aile (family) tipi sağlayıcıdır.
 * Parametre olarak 'restaurantId' alır ve otomatik olarak veriyi getirir.
 */
final menuByRestaurantProvider = FutureProvider.family<List<MenuItemModel>, int>(
      (ref, restaurantId) =>
      ref.read(menuRepositoryProvider).getByRestaurant(restaurantId),
);