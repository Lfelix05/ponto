import 'package:cloud_firestore/cloud_firestore.dart';

class Ponto {
  final String id;
  final String name;
  String location;
  final DateTime checkIn;
  DateTime? checkOut;

  Ponto({
    required this.id,
    required this.name,
    required this.location,
    required this.checkIn,
    this.checkOut,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut?.toIso8601String(),
    };
  }

  factory Ponto.fromJson(Map<String, dynamic> json) {
    return Ponto(
      id: json['id'],
      name: json['name'],
      location: (json['location'] ?? '').toString(),
      checkIn:
          json['checkIn'] is Timestamp
              ? (json['checkIn'] as Timestamp).toDate()
              : DateTime.parse(json['checkIn'].toString()),
      checkOut:
          json['checkOut'] != null
              ? (json['checkOut'] is Timestamp
                  ? (json['checkOut'] as Timestamp).toDate()
                  : DateTime.parse(json['checkOut'].toString()))
              : null,
    );
  }
}
