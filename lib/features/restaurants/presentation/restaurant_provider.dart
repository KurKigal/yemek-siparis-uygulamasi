import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/restaurant_repository.dart';
import '../domain/restaurant_model.dart';

/**
 * Arayüz tarafında restoran listesini asenkron olarak dinlemeyi sağlayan aile (family) sağlayıcısı.
 * Parametre olarak gönderilen 'query' (arama metni) değiştiğinde otomatik olarak
 * backend'den yeni veriyi çeker ve arayüzü günceller.
 */
final restaurantListProvider = FutureProvider.family<List<RestaurantModel>, String?>(
      (ref, query) => ref.read(restaurantRepositoryProvider).getAll(query: query),
);

/**
 * Belirli bir restorana tıklandığında, o restoranın detaylarını ID bazlı
 * olarak asenkron şekilde çeken ve önbellekte tutan sağlayıcıdır.
 */
final restaurantDetailProvider = FutureProvider.family<RestaurantModel, int>(
      (ref, id) => ref.read(restaurantRepositoryProvider).getById(id),
);