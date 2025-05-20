class Ponto {
  final String id;
  final String name;
  final String location;
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
      checkIn: DateTime.parse(json['checkIn']),
      checkOut:
          json['checkOut'] != null ? DateTime.parse(json['checkOut']) : null,
    );
  }
}