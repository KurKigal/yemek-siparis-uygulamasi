import 'package:flutter/material.dart';

/**
 * Uygulama genelinde standart ve tutarlı bir metin giriş alanı (TextField) tasarımı
 * sunmak için oluşturulmuş özelleştirilebilir arayüz bileşenidir.
 */
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final Widget? suffixIcon;
  final IconData? prefixIcon;
  final bool enabled;

  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.suffixIcon,
    this.prefixIcon,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Giriş alanının üst kısmında yer alan başlık (Etiket)
        Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)
        ),
        const SizedBox(height: 6),

        // Kullanıcının metin gireceği form alanı
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          // Ağ isteği (API çağrısı) yapılıyorken formun kilitlenmesini sağlar.
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            // Sol tarafa eklenecek opsiyonel bilgilendirme ikonu
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey[600]) : null,
            // Sağ tarafa eklenecek opsiyonel aksiyon ikonu (Örn: Şifre göster/gizle)
            suffixIcon: suffixIcon,
            // Genel kenarlık tasarımı
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            // Odaklanılmadığı durumlardaki varsayılan kenarlık stili
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ],
    );
  }
}