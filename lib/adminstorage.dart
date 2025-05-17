import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin.dart'; 

class AdminStorage {
  static const _adminKey = 'admin_data';
  
  static Future<String> _generateId() async {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  static Future<void> saveAdmin(String name, String email, String password) async {
    final id = await _generateId();
    final admin = Admin(
      id: id,
      name: name,
      email: email,
      password: password,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminKey, jsonEncode(admin.toJson()));
  }

  static Future<Admin?> getAdmin() async {
  final prefs = await SharedPreferences.getInstance();
  final adminData = prefs.getString(_adminKey);
  
  if (adminData != null) {
    final decoded = jsonDecode(adminData);
    return Admin(
      id: decoded['id'],
      name: decoded['name'],
      email: decoded['email'],
      password: decoded['password'],
    );
  }
  return null;
}
static Future<void> clearAdmin() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(_adminKey); // Remove os dados do admin
}

}
