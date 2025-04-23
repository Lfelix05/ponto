class Admin {
  final String id;
  final String name;
  final String phone;
  final String password;

  Admin({required this.id, required this.name, required this.phone, required this.password});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phone': phone,
    'password': password,
  };

  // Cria a partir de JSON
  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      password: json['password'],
    );
  }

}
