class Employee {
  final String id;
  final String name;
  final String email;
  final String password;
  final bool selected;

  Employee({required this.id, required this.name, required this.email,required this.password, required this.selected});


  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'selected': selected
      };

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      password: json['password'],
      selected: json['selected']
    );
  }
}