import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../features/auth/presentation/auth_provider.dart';

/**
 * Admin kullanıcısının sistemdeki tüm restoranları görüntülemesini sağlayan,
 * verileri API üzerinden asenkron olarak çeken Riverpod sağlayıcısı.
 */
final adminRestaurantsProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get(ApiConstants.restaurants);
  return res.data;
});

/**
 * Sadece 'admin' rolündeki kullanıcıların erişebildiği, sistemdeki tüm restoranların
 * listelendiği, yenilerinin eklenebildiği ve mevcutların düzenlenip silinebildiği yönetim paneli arayüzü.
 */
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantsAsync = ref.watch(adminRestaurantsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Admin Paneli', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
            tooltip: 'Çıkış Yap',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showRestaurantForm(context, ref, null),
        backgroundColor: Colors.black87,
        icon: const Icon(Icons.add_business, color: Colors.white),
        label: const Text('Restoran Ekle', style: TextStyle(color: Colors.white)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Admine özel karşılama ve genel bilgilendirme kartı alanı
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black87,
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings, size: 48, color: Colors.amber),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hoşgeldin, ${user?.name ?? 'Yönetici'}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text('Sistemdeki tüm işletmeleri buradan yönetebilirsiniz.',
                          style: TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sisteme kayıtlı olan restoranların çekilip listelendiği, yüklenme ve hata durumlarının kontrol edildiği bölüm
          Expanded(
            child: restaurantsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: Colors.black87)),
              error: (e, _) => Center(child: Text('Hata: $e')),
              data: (restaurants) {
                if (restaurants.isEmpty) {
                  return const Center(child: Text('Sistemde kayıtlı restoran yok.'));
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(adminRestaurantsProvider),
                  color: Colors.black87,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: restaurants.length,
                    itemBuilder: (context, index) {
                      final rest = restaurants[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: rest['logo_url'] != null
                                ? Image.network(rest['logo_url'], width: 60, height: 60, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder())
                                : _placeholder(),
                          ),
                          title: Text(rest['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Sahip ID: ${rest['owner_id']} \n${rest['address'] ?? 'Adres yok'}', maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showRestaurantForm(context, ref, rest),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteRestaurant(context, ref, rest['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /**
   * Resim yüklenemediğinde veya logo bulunmadığında gösterilen varsayılan görsel bileşeni.
   */
  Widget _placeholder() => Container(
    width: 60, height: 60, color: Colors.grey[200],
    child: const Icon(Icons.store, color: Colors.grey),
  );

  /**
   * Restoranı sistemden kaldırmak için tetiklenen uyarı diyalogu ve backend silme işlemi.
   */
  void _deleteRestaurant(BuildContext context, WidgetRef ref, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restoranı Sil'),
        content: const Text('Bu işlem restoranı ve ona bağlı tüm menüleri silebilir. Emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(dioProvider).delete('${ApiConstants.restaurants}/$id');
        ref.invalidate(adminRestaurantsProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
        }
      }
    }
  }

  /**
   * Yeni restoran eklemek veya var olanı düzenlemek için ekranın altından kayarak açılan form (Bottom Sheet).
   * Eğer existingRest null ise ekleme modu, değilse düzenleme (update) modu aktif olur.
   */
  void _showRestaurantForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? existingRest) {
    final isEdit = existingRest != null;
    final ownerCtrl = TextEditingController(text: isEdit ? existingRest['owner_id'].toString() : '');
    final nameCtrl = TextEditingController(text: isEdit ? existingRest['name'] : '');
    final descCtrl = TextEditingController(text: isEdit ? existingRest['description'] : '');
    final addrCtrl = TextEditingController(text: isEdit ? existingRest['address'] : '');
    final logoCtrl = TextEditingController(text: isEdit ? existingRest['logo_url'] : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEdit ? 'Restoranı Düzenle' : 'Yeni Restoran Ekle', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // Düzenleme modunda sahibi değiştirmeye izin verilmez, sadece ekleme aşamasında owner_id istenir
              if (!isEdit)
                TextField(controller: ownerCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sahibinin Kullanıcı ID\'si (owner_id)', border: OutlineInputBorder())),
              if (!isEdit) const SizedBox(height: 12),

              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Restoran Adı', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Adres', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Açıklama', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: logoCtrl, decoration: const InputDecoration(labelText: 'Logo URL (İsteğe bağlı)', border: OutlineInputBorder())),
              const SizedBox(height: 24),

              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  if (!isEdit && ownerCtrl.text.isEmpty) return;

                  final data = {
                    'name': nameCtrl.text,
                    'address': addrCtrl.text,
                    'description': descCtrl.text,
                    'logo_url': logoCtrl.text,
                  };

                  if (!isEdit) data['owner_id'] = ownerCtrl.text;

                  try {
                    if (isEdit) {
                      await ref.read(dioProvider).put('${ApiConstants.restaurants}/${existingRest['id']}', data: data);
                    } else {
                      await ref.read(dioProvider).post(ApiConstants.restaurants, data: data);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);

                    // İşlem başarılı olursa arayüzdeki listeyi yenilemesi için provider tetiklenir
                    ref.invalidate(adminRestaurantsProvider);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Hata: $e')));
                    }
                  }
                },
                child: Text(isEdit ? 'Güncelle' : 'Ekle', style: const TextStyle(color: Colors.white, fontSize: 16)),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}