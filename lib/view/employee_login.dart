import 'package:flutter/material.dart';
import 'package:ponto/view/employee_panel.dart';
import '../database.dart';

class EmployeeLogin extends StatefulWidget {
  const EmployeeLogin({super.key});

  @override
  _EmployeeLoginState createState() => _EmployeeLoginState();
}

class _EmployeeLoginState extends State<EmployeeLogin> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _loginEmployee(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final name = nameController.text;
      final phone = phoneController.text;

      try {
        // Verifica se o funcionário existe no banco de dados
        final employee = await Database.getEmployees().then((employees) {
          return employees.firstWhere(
            (e) => e.name == name && e.phone == phone,
            orElse: () {
              throw Exception('Funcionário não encontrado');
            },
          );
        });

        // Redireciona para o painel do funcionário
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmployeePanel(employee: employee),
          ),
        );
      } catch (e) {
        // Exibe mensagem de erro se o funcionário não for encontrado
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Funcionário')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Nome do Funcionário'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o nome do funcionário';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(labelText: 'Número de Telefone'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira o número de telefone';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return 'Por favor, insira apenas números';
                  }
                  return null;
                },
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _loginEmployee(context),
                child: Text('Entrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
