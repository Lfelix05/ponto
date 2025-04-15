import 'employee.dart';

class Database {
  static List<Employee> employees = [];

  static Future<List<Employee>> getEmployees() async {
    return employees;
  }

  static void addEmployee(String name, String location, String checkIn) {
    employees.add(Employee(id: DateTime.now().toString(), name: name, location: location, checkIn: checkIn));
  }

  static void updateCheckOut(String id, String checkOut) {
    for (var employee in employees) {
      if (employee.id == id) {
        employee.checkOut = checkOut as DateTime?;
      }
    }
  }

  static void deleteEmployee(String id) {
    employees.removeWhere((e) => e.id == id);
  }
}
