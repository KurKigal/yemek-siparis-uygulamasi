import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../core/constants/app_theme.dart';
import '../domain/user_model.dart';
import 'auth_provider.dart';

/**
 * Yeni kullanıcıların sisteme kaydolmasını sağlayan arayüz bileşeni.
 * Ad, e-posta, şifre ve hesap rolü (Müşteri/Restoran Sahibi) verilerini toplayarak
 * backend servisine iletir.
 */
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _nameCtrl      = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  String _role = 'customer';
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  /**
   * Tüm alanların eksiksiz doldurulduğunu teyit ettikten sonra
   * kayıt (register) işlemini başlatır.
   */
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    await ref.read(authProvider.notifier).register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      role: _role,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Kayıt esnasında oluşabilecek e-posta çakışması vb. hataları ekranda gösterir.
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

    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                Text(
                  'Kayıt Ol',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Yeni bir hesap oluşturun',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                // Ad Soyad giriş alanı.
                AppTextField(
                  controller: _nameCtrl,
                  label: 'Ad Soyad',
                  hint: 'Adınızı ve soyadınızı girin',
                  prefixIcon: Icons.person_outline,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ad Soyad boş bırakılamaz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // E-posta giriş alanı.
                AppTextField(
                  controller: _emailCtrl,
                  label: 'E-posta',
                  hint: 'E-posta adresinizi girin',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-posta boş bırakılamaz';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir e-posta girin';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Şifre giriş ve görünürlük alanı.
                AppTextField(
                  controller: _passwordCtrl,
                  label: 'Şifre',
                  hint: 'Şifrenizi girin',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscure,
                  enabled: !isLoading,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility_off : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscure = !_obscure;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre boş bırakılamaz';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalıdır';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Sistemdeki yetki sınırlarını belirleyen rol seçici alan.
                Text(
                  'Hesap Türü',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleChip(
                        label: 'Müşteri',
                        value: 'customer',
                        selected: _role == 'customer',
                        onTap: () {
                          if (!isLoading) setState(() => _role = 'customer');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _RoleChip(
                        label: 'Restoran Sahibi',
                        value: 'restaurant_owner',
                        selected: _role == 'restaurant_owner',
                        onTap: () {
                          if (!isLoading) setState(() => _role = 'restaurant_owner');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Bilgileri sunucuya gönderen onay butonu.
                LoadingButton(
                  text: 'Kayıt Ol',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
                const SizedBox(height: 24),

                // Zaten hesabı olanları giriş ekranına yönlendiren bağlantı metni.
                GestureDetector(
                  onTap: () {
                    if (!isLoading) context.go('/login');
                  },
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      children: [
                        const TextSpan(
                            text: 'Zaten hesabın var mı? ',
                            style: TextStyle(color: Colors.grey)
                        ),
                        TextSpan(
                          text: 'Giriş Yap',
                          style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600
                          ),
                        ),
                      ],
                    ),
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

/**
 * Rol seçimlerini (Müşteri/Sahip) görsel olarak belirginleştiren özel kutucuk (Chip) tasarımı.
 */
class _RoleChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primaryColor.withOpacity(0.1) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppTheme.primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: selected ? AppTheme.primaryColor : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }
}