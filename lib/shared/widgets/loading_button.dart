import 'package:flutter/material.dart';
import '../../core/constants/app_theme.dart';

/**
 * Kullanıcı bir aksiyon aldığında (Giriş yap, Kayıt ol, Sipariş ver vb.)
 * işlemin arka planda devam ettiğini göstermek için yüklenme (spinner) animasyonu
 * barındıran dinamik buton bileşenidir.
 */
class LoadingButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;

  const LoadingButton({
    super.key,
    required this.text,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // İşlem devam ediyorsa art arda tıklanmayı önlemek için buton tıklama özelliğini pasif hale getirir.
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppTheme.primaryColor.withOpacity(0.6),
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      // Eğer yüklenme durumu aktifse metin yerine dairesel ilerleme çubuğu (CircularProgressIndicator) gösterilir.
      child: isLoading
          ? const SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2.5,
        ),
      )
          : Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}