import 'dart:convert';
import 'package:crypto/crypto.dart';  //para criptografar a senha

class Admin {
  final String id;
  final String name;
  final String email;
  final String password;

  Admin({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
  });

  // Gera o hash da senha
  String get hashedPassword {
    final bytes = utf8.encode(password);      // Converte a senha para bytes
    return sha256.convert(bytes).toString();  // Retorna o hash SHA-256
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'password': hashedPassword,         // Salva o hash da senha
  };

  // Cria a partir de JSON
  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],       // O hash será usado como senha
    );
  }
}
