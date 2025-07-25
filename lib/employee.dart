import 'dart:convert';
import 'package:crypto/crypto.dart';  // para criptografar a senha
class Employee {
  final String id;
  final String name;
  final String phone;
  final String password;
  final bool selected;
  String? checkIn_Time;
  String? verificationCode;
  List<String>? notificationDays;

  Employee({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    required this.selected,
    required this.checkIn_Time,
    required this.verificationCode,
    this.notificationDays,
  });


  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'password': hashedPassword,
        'selected': selected,
        'checkIn_Time': checkIn_Time,
        'verificationCode': verificationCode,
        'notificationDays': notificationDays,
      };

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      password: json['password'] ?? '',
      selected: json['selected'] ?? false,
      checkIn_Time: json['checkIn_Time'] ?? '',
      verificationCode: json['verificationCode'] ?? '',
      notificationDays: List<String>.from(json['notificationDays'] ?? []),
    );
  }
  String get hashedPassword {
    final bytes = utf8.encode(password);      // Converte a senha para bytes
    return sha256.convert(bytes).toString();  // Retorna o hash SHA-256
  }
}