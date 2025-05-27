class Employee {
  final String id;
  final String name;
  final String phone;
  final String password;
  final bool selected;

  Employee({required this.id, required this.name, required this.phone,required this.password, required this.selected});


  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'password': password,
        'selected': selected
      };

  factory Employee.fromJson(Map<String, dynamic> json) {
  return Employee(
    id: json['id'] ?? '',
    name: json['name'] ?? '',
    phone: json['phone'] ?? '',
    password: json['password'] ?? '',
    selected: json['selected'] ?? false,
  );
}
}