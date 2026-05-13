/**
 * Kullanıcı verisini Dart nesnesi olarak soyutlayan ve JSON dönüşümlerini
 * gerçekleştiren model (entity) sınıfı.
 */
class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    role: json['role'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role,
  };

  /**
   * Mantıksal operasyonlarda arayüzü sadeleştiren kontrol metodları.
   */
  bool get isOwner => role == 'restaurant_owner';
  bool get isAdmin  => role == 'admin';
}