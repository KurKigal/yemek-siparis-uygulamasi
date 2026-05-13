import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';
import '../../../features/auth/presentation/auth_provider.dart';
import '../../../features/orders/data/order_repository.dart';
import '../../../core/network/dio_client.dart';

/**
 * Restoran sahiplerine özel, kendi işletmelerine ait sipariş verilerini
 * asenkron olarak çekip arayüze sunan Riverpod sağlayıcısıdır.
 */
final ownerOrdersProfileProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  return ref.watch(orderRepositoryProvider).getRestaurantOrders();
});

/**
 * Kullanıcıların kişisel bilgilerini, hesap rollerini (Müşteri veya Restoran Sahibi)
 * ve bu rollere göre değişen istatistiklerini görüntülediği ana profil ekranı.
 */
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    // Kullanıcı bilgisi hafızaya alınana kadar ekranda yükleme animasyonu gösterilir.
    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
      );
    }

    // Uygulama arayüzünün kullanıcının yetkisine göre şekillenmesini sağlayan rol kontrolü.
    final bool isOwner = user.role == 'restaurant_owner';

    // Kullanıcının rolüne göre doğru veri sağlayıcısı dinlenmeye başlanır.
    // Müşteriler kendi verdikleri siparişleri, restoran sahipleri ise aldıkları siparişleri çeker.
    final AsyncValue<List<dynamic>> statsAsync = isOwner
        ? ref.watch(ownerOrdersProfileProvider)
        : ref.watch(myOrdersProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Profilim', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Kullanıcının adının baş harfini, tam adını, e-postasını ve hesap türünü gösteren üst alan.
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 42,
                  backgroundColor: AppTheme.primaryColor.withAlpha(38),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isOwner ? 'Restoran Sahibi' : 'Müşteri',
                    style: const TextStyle(
                        color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Role göre dinamik olarak hesaplanan verilerin (Harcama veya Kazanç vb.) sunulduğu istatistik kartı.
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withAlpha(76),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: statsAsync.when(
              data: (orders) {
                final totalOrders = orders.length;
                final completedOrders = orders.where((o) => o['status'] == 'teslim_edildi').length;
                final totalMoney = orders.fold<double>(0, (sum, item) => sum + (item['total_price'] as num).toDouble());

                return Row(
                  children: [
                    _StatItem(totalOrders.toString(), isOwner ? 'Gelen Sipariş' : 'Sipariş'),
                    _divider(),
                    _StatItem(completedOrders.toString(), 'Tamamlanan'),
                    _divider(),
                    _StatItem('${totalMoney.toStringAsFixed(1)} ₺', isOwner ? 'Kazanç' : 'Harcama'),
                  ],
                );
              },
              loading: () => Row(
                children: [
                  _StatItem('-', isOwner ? 'Gelen Sipariş' : 'Sipariş'),
                  _divider(),
                  const _StatItem('-', 'Tamamlanan'),
                  _divider(),
                  _StatItem('-', isOwner ? 'Kazanç' : 'Harcama'),
                ],
              ),
              error: (_, __) => Row(
                children: [
                  _StatItem('0', isOwner ? 'Gelen Sipariş' : 'Sipariş'),
                  _divider(),
                  const _StatItem('0', 'Tamamlanan'),
                  _divider(),
                  _StatItem('0 ₺', isOwner ? 'Kazanç' : 'Harcama'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Sadece 'Müşteri' rolündekilerin görebildiği kişisel bilgi güncelleme menüsü.
          if (!isOwner)
            _MenuItem(
              icon: Icons.edit_note,
              label: 'Bilgilerimi Güncelle',
              onTap: () => _showEditProfileDialog(context, ref, user.name, user.email),
            ),

          // Sadece 'Müşteri' rolündekilerin görebildiği geçmiş siparişlere yönlendiren menü.
          if (!isOwner)
            _MenuItem(
              icon: Icons.receipt_long,
              label: 'Sipariş Geçmişim',
              onTap: () {
                context.go('/orders');
              },
            ),

          // Sadece 'Restoran Sahibi' rolündekilerin görebildiği işletme ayarları menüsü.
          if (isOwner)
            _MenuItem(
              icon: Icons.storefront,
              label: 'Restoran Ayarları',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Restoran ayarları çok yakında eklenecek!')),
                );
              },
            ),

          // Tüm rollerin erişebildiği şifre değiştirme ve yardım menüleri.
          _MenuItem(
            icon: Icons.lock_outline,
            label: 'Şifre Değiştir',
            onTap: () {
              _showChangePasswordDialog(context, ref);
            },
          ),
          _MenuItem(
            icon: Icons.help_outline,
            label: 'Yardım ve Destek',
            onTap: () {},
          ),
          const SizedBox(height: 16),

          // Oturumu güvenli bir şekilde kapatmayı sağlayan sistemden çıkış butonu.
          _MenuItem(
            icon: Icons.logout,
            label: 'Çıkış Yap',
            color: Colors.red,
            onTap: () async {
              final router = GoRouter.of(context);

              final confirm = await showDialog<bool>(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Çıkış Yap', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: const Text('Hesabınızdan çıkmak istiyor musunuz?'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(false),
                      child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogCtx).pop(true),
                      child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(authProvider.notifier).logout();
                router.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}

/**
 * İstatistik kartında yer alan sayısal değerleri ve etiketleri dikey düzende gösteren yardımcı bileşen.
 */
class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    ),
  );
}

/**
 * İstatistik öğelerini birbirinden şık bir biçimde ayıran dikey çizgi (ayraç) tasarımı.
 */
Widget _divider() => Container(
  width: 1,
  height: 36,
  color: Colors.white.withAlpha(76),
);

/**
 * Profil ekranının alt bölümünde yer alan yönlendirme ve işlem menülerinin standart görünüm bileşeni.
 */
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 6,
            offset: const Offset(0, 2))
      ],
    ),
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? Colors.grey[700]),
      title: Text(
        label,
        style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color ?? Colors.black87),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
    ),
  );
}

/**
 * Müşteri rolündeki kullanıcıların kişisel ad, soyad ve e-posta verilerini
 * güncelleyebilmesini sağlayan form penceresi (dialog) fonksiyonudur.
 */
void _showEditProfileDialog(BuildContext context, WidgetRef ref, String currentName, String currentEmail) {
  final nameCtrl = TextEditingController(text: currentName);
  final emailCtrl = TextEditingController(text: currentEmail);
  final formKey = GlobalKey<FormState>();

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Bilgileri Güncelle', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'Ad Soyad',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Boş bırakılamaz' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Boş bırakılamaz' : null,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('İptal', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              try {
                // API üzerinden güncel bilgileri backend'e gönderir.
                await ref.read(dioProvider).put('/auth/profile', data: {
                  'name': nameCtrl.text.trim(),
                  'email': emailCtrl.text.trim(),
                });

                // Başarılı güncelleme sonrasında uygulama genelindeki kimlik sağlayıcısını yeniler.
                ref.invalidate(authProvider);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Profiliniz başarıyla güncellendi!'),
                        backgroundColor: Colors.green
                    ),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Güncelleme başarısız: $e'),
                        backgroundColor: Colors.red
                    ),
                  );
                }
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Kaydet', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

/**
 * Kullanıcının mevcut şifresini güvenlik amacıyla tekrar girmesini sağlayıp,
 * hesabı için yeni bir şifre belirlemesine imkan tanıyan açılır pencere (dialog) fonksiyonu.
 */
void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
  final oldPasswordCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Şifre Değiştir', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: oldPasswordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Mevcut Şifre',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v!.isEmpty ? 'Boş bırakılamaz' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: newPasswordCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Yeni Şifre',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (v) => v != null && v.length < 6 ? 'En az 6 karakter' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('İptal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                    if (formKey.currentState!.validate()) {
                      setState(() => isLoading = true);
                      try {
                        await ref.read(authProvider.notifier).changePassword(
                          oldPasswordCtrl.text,
                          newPasswordCtrl.text,
                        );
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Şifreniz başarıyla değiştirildi!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        setState(() => isLoading = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isLoading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Kaydet', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
      );
    },
  );
}