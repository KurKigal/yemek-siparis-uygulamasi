import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/app_theme.dart';

/**
 * Restoran sahibine ait olan menü ürünlerini backend üzerinden
 * asenkron olarak çeken ve veriyi önbellekte tutan Riverpod sağlayıcısıdır.
 */
final ownerMenuProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('${ApiConstants.menu}/owner');
  return res.data;
});

/**
 * Restoran sahibinin kendi menüsünü görüntüleyebildiği, yeni ürünler ekleyip
 * mevcut ürünleri düzenleyebildiği veya silebildiği (CRUD) yönetim ekranı.
 */
class OwnerMenuScreen extends ConsumerWidget {
  const OwnerMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Menü verisinin anlık yüklenme, hata veya başarı durumunu dinler.
    final menuAsync = ref.watch(ownerMenuProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Menü Yönetimi', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // Ekranın sağ alt köşesinde bulunan ve yeni ürün ekleme formunu tetikleyen buton.
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(context, ref, null),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Ürün Ekle', style: TextStyle(color: Colors.white)),
      ),
      body: menuAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (e, _) => Center(child: Text('Hata oluştu: $e')),
        data: (menu) {
          // Menüde hiç ürün yoksa kullanıcıya gösterilecek boş durum tasarımı.
          if (menu.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.restaurant_menu, size: 72, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text('Menünüzde henüz ürün yok.', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          // Sayfa yukarıdan aşağı doğru çekildiğinde menü verilerini API'den tekrar çeker.
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(ownerMenuProvider),
            color: AppTheme.primaryColor,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: menu.length,
              itemBuilder: (context, index) {
                final item = menu[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      // Ürünün geçerli bir görsel linki varsa ağdan yükler, aksi halde yer tutucu (placeholder) gösterir.
                      child: item['image_url'] != null && item['image_url'].toString().isNotEmpty
                          ? Image.network(item['image_url'], width: 60, height: 60, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder())
                          : _placeholder(),
                    ),
                    title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('₺${item['price']}  •  Stok: ${item['stock']}',
                              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                    // Düzenleme ve Silme butonlarını barındıran sağ kısım.
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _showProductForm(context, ref, item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProduct(context, ref, item['id']),
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
    );
  }

  /**
   * Resim yüklenememesi veya hiç girilmemesi durumunda ürün listesinde
   * görsel bütünlüğü korumak için gösterilen alternatif (varsayılan) kutu bileşeni.
   */
  Widget _placeholder() => Container(
    width: 60, height: 60, color: Colors.grey[200],
    child: const Icon(Icons.fastfood, color: Colors.grey),
  );

  /**
   * Belirtilen menü ürününü silmek için öncelikle kullanıcıdan bir onay diyalogu alır.
   * Onay verilirse backend API üzerinden ürünü (soft delete) siler ve arayüzü günceller.
   */
  void _deleteProduct(BuildContext context, WidgetRef ref, int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: const Text('Bu ürünü menüden kaldırmak istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(dioProvider).delete('${ApiConstants.menu}/$id');
        ref.invalidate(ownerMenuProvider);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silme başarısız!')));
        }
      }
    }
  }

  /**
   * Yeni ürün oluşturmak veya var olan bir ürünü düzenlemek için ekranın altından
   * yukarı doğru açılan kapsamlı form ekranını (Bottom Sheet) oluşturur.
   */
  void _showProductForm(BuildContext context, WidgetRef ref, Map<String, dynamic>? existingItem) {
    // Eğer existingItem gönderilmişse güncelleme (Edit), gönderilmemişse ekleme (Add) modudur.
    final isEdit = existingItem != null;

    // Düzenleme modunda form alanlarına mevcut ürünün bilgileri yerleştirilir.
    final nameCtrl = TextEditingController(text: isEdit ? existingItem['name'] : '');
    final descCtrl = TextEditingController(text: isEdit ? existingItem['description'] : '');
    final priceCtrl = TextEditingController(text: isEdit ? existingItem['price'].toString() : '');
    final stockCtrl = TextEditingController(text: isEdit ? existingItem['stock'].toString() : '100');
    final imageCtrl = TextEditingController(text: isEdit ? existingItem['image_url'] : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        // Klavyenin formu kapatmasını engellemek için dinamik alt boşluk (viewInsets.bottom) eklenir.
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(isEdit ? 'Ürünü Düzenle' : 'Yeni Ürün Ekle', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Ürün Adı', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Fiyat (₺)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: stockCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Stok Adedi', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Açıklama (İsteğe bağlı)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: imageCtrl, decoration: const InputDecoration(labelText: 'Görsel URL (İsteğe bağlı)', border: OutlineInputBorder())),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) return;

                  final data = {
                    'name': nameCtrl.text,
                    'price': double.parse(priceCtrl.text),
                    'stock': int.parse(stockCtrl.text),
                    'description': descCtrl.text,
                    'image_url': imageCtrl.text,
                  };

                  try {
                    // isEdit bayrağına göre doğru HTTP metodunu (POST veya PUT) seçerek API isteğini atar.
                    if (isEdit) {
                      await ref.read(dioProvider).put('${ApiConstants.menu}/${existingItem['id']}', data: data);
                    } else {
                      await ref.read(dioProvider).post(ApiConstants.menu, data: data);
                    }
                    if (ctx.mounted) Navigator.pop(ctx);

                    // İşlem başarıyla tamamlandığında güncel menüyü ekrana yansıtmak için sağlayıcı yenilenir.
                    ref.invalidate(ownerMenuProvider);
                  } catch (e) {

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