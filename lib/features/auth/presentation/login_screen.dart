import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../core/constants/app_theme.dart';
import '../domain/user_model.dart';
import 'auth_provider.dart';

/**
 * Kullanıcıların e-posta ve şifreleri ile sisteme oturum açmasını sağlayan arayüz bileşeni.
 * Riverpod kullanılarak asenkron durum yönetimi (yüklenme ve hata takibi) sağlanır.
 */
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /**
   * Form alanlarının geçerliliğini denetler ve sorun yoksa kimlik doğrulama işlemini başlatır.
   * API isteği atılmadan önce sanal klavyeyi kapatarak daha iyi bir kullanıcı deneyimi sunar.
   */
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kimlik doğrulama durumu dinlenerek, başarısız giriş denemelerinde
    // kullanıcıya hata mesajını barındıran bir uyarı balonu (SnackBar) gösterilir.
    ref.listen<AsyncValue<UserModel?>>(authProvider, (previous, next) {
      if (next.hasError && !next.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    // İstek devam ediyorsa butonların devre dışı kalmasını sağlayan yüklenme durumu alınır.
    final isLoading = ref.watch(authProvider).isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // Karşılama başlığı ve uygulama logosunun bulunduğu üst alan.
                Center(
                  child: Column(children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.restaurant, size: 48, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    const Text('Hoş Geldiniz',
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Hesabınıza giriş yapın',
                        style: TextStyle(color: Colors.grey)),
                  ]),
                ),
                const SizedBox(height: 40),

                // E-posta giriş alanı. Biçim doğrulaması içerir.
                AppTextField(
                  label: 'E-posta',
                  hint: 'ornek@mail.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  enabled: !isLoading,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'E-posta zorunludur';
                    if (!v.contains('@')) return 'Geçerli e-posta girin';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Şifre giriş alanı. Görünürlüğü açıp kapama (göz ikonu) işlevini içerir.
                AppTextField(
                  label: 'Şifre',
                  hint: '••••••••',
                  controller: _passwordCtrl,
                  obscureText: _obscure,
                  prefixIcon: Icons.lock_outline,
                  enabled: !isLoading,
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'En az 6 karakter girin';
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Giriş işlemini tetikleyen animasyonlu yükleme butonu.
                LoadingButton(
                  text: 'Giriş Yap',
                  isLoading: isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 16),

                // Hesabı olmayan kullanıcıları kayıt olma ekranına yönlendiren bağlantı.
                Center(
                  child: TextButton(
                    onPressed: () {
                      if (!isLoading) context.push('/register');
                    },
                    child: const Text.rich(TextSpan(children: [
                      TextSpan(text: 'Hesabın yok mu? ', style: TextStyle(color: Colors.grey)),
                      TextSpan(text: 'Kayıt Ol', style: TextStyle(
                          color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                    ])),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}