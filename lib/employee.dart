class Employee {
  final String id;
  final String name;
  final String location;
  final String checkIn;
  DateTime? checkOut;

  Employee({
    required this.id,
    required this.name,
    required this.location,
    required this.checkIn,
    this.checkOut,
  });
}
