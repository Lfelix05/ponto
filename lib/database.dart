import 'employee.dart';
import 'ponto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Database {
  // Lista de funcionários
  static List<Employee> employees = [];

  // Lista de registros de ponto
  static List<Ponto> pontos = [];

  // Retorna a lista de funcionários
  static Future<List<Employee>> getEmployees() async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('employees')
            .where('selected', isEqualTo: true)
            .get();

    return snapshot.docs.map((doc) => Employee.fromJson(doc.data())).toList();
  }

  // Adiciona um novo funcionário
  static void addEmployee(String name, String password) {
    final employee = Employee(
      id: DateTime.now().toString(), // Gera um ID único para o funcionário
      name: name,
      email: '',
      password: password,
      selected: false,
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

  // Atualiza o horário de saída (checkOut) no Firestore
  static Future<void> updateCheckOut(
    String employeeId,
    String checkOut,
    String locationCheckOut,
  ) async {
    // Busca o último ponto aberto (sem checkOut)
    final pontosRef = FirebaseFirestore.instance
        .collection('employees')
        .doc(employeeId)
        .collection('pontos');
    final snapshot =
        await pontosRef
            .where('checkOut', isEqualTo: null)
            .orderBy('checkIn', descending: true)
            .limit(1)
            .get();

    if (snapshot.docs.isNotEmpty) {
      final docId = snapshot.docs.first.id;
      await pontosRef.doc(docId).update({
        'checkOut': checkOut,
        'locationCheckOut':
            locationCheckOut, // salva a localização do check-out
      });
    }
  }

  // Remove um funcionário e seus registros de ponto
  static void deleteEmployee(String employeeId) {
    employees.removeWhere((e) => e.id == employeeId);
    pontos.removeWhere((p) => p.id == employeeId);
  }

  // Retorna os registros de ponto de um funcionário específico
  static Future<List<Ponto>> getPontosByEmployeeId(String employeeId) async {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('employees')
            .doc(employeeId)
            .collection('pontos')
            .orderBy('checkIn', descending: false)
            .get();

    return snapshot.docs.map((doc) => Ponto.fromJson(doc.data())).toList();
  }
}
