import 'package:flutter/material.dart';

/**
 * Uygulamanın genel renk paletini ve arayüz (UI) bileşenlerinin standart
 * tasarımlarını (Tema) belirleyen yapılandırma sınıfı.
 */
class AppTheme {
  // Uygulama genelinde kullanılacak birincil (marka) ve ikincil renkler
  static const primaryColor = Color(0xFFFF6B35);
  static const secondaryColor = Color(0xFF2D2D2D);

  // Uygulamanın aydınlık (light) temasını ve bileşen özelliklerini döndürür
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),

    // Üst gezinme çubuğunun standart görünüm ayarları
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: secondaryColor,
      elevation: 0,
      centerTitle: true,
    ),

    // Uygulama içindeki tüm dolgulu butonların (ElevatedButton) standart stili
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),

    // Metin giriş alanlarının (TextField) arka plan, kenarlık ve boşluk ayarları
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}