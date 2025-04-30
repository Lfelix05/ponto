import 'employee.dart';
import 'ponto.dart';

class Database {
  // Lista de funcionários
  static List<Employee> employees = [];

  // Lista de registros de ponto
  static List<Ponto> pontos = [];

  // Retorna a lista de funcionários
  static Future<List<Employee>> getEmployees() async {
    return employees;
  }

  // Adiciona um novo funcionário
  static void addEmployee(String name, String phone) {
    final employee = Employee(
      id: DateTime.now().toString(), // Gera um ID único para o funcionário
      name: name,
      phone: phone,
    );
    employees.add(employee); // Adiciona o funcionário à lista de funcionários
  }

  // Adiciona um registro de ponto para um funcionário
  static void addPonto(String employeeId, String location, String checkIn) {
    pontos.add(
      Ponto(
        id: employeeId,
        name: employees.firstWhere((e) => e.id == employeeId).name,
        location: location,
        checkIn: DateTime.parse(checkIn),
      ),
    );
  }

  // Atualiza o horário de saída (checkOut) de um registro de ponto
  static void updateCheckOut(String employeeId, String checkOut) {
    for (var ponto in pontos) {
      if (ponto.id == employeeId && ponto.checkOut == null) {
        ponto.checkOut = DateTime.parse(checkOut);
        break;
      }
    }
  }

  // Remove um funcionário e seus registros de ponto
  static void deleteEmployee(String employeeId) {
    employees.removeWhere((e) => e.id == employeeId);
    pontos.removeWhere((p) => p.id == employeeId);
  }

  // Retorna os registros de ponto de um funcionário específico
  static Future<List<Ponto>> getPontosByEmployeeId(String employeeId) async {
    // Simula um atraso para representar uma consulta ao banco de dados
    await Future.delayed(Duration(milliseconds: 500));

    // Filtra os registros de ponto pelo ID do funcionário
    return pontos.where((ponto) => ponto.id == employeeId).toList();
  }
}
