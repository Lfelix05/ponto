import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ponto/utils/validator.dart';
import 'package:ponto/view/employee_panel.dart';
import 'package:ponto/view/employee_register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../employee.dart';

class EmployeeLogin extends StatefulWidget {
  const EmployeeLogin({super.key});

  @override
  _EmployeeLoginState createState() => _EmployeeLoginState();
}

class _EmployeeLoginState extends State<EmployeeLogin> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _loginEmployee(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      try {
        final phone = phoneController.text.trim();
        final password = passwordController.text;

        // Busca o funcionário pelo telefone
        final query =
            await FirebaseFirestore.instance
                .collection('employees')
                .where('phone', isEqualTo: phone)
                .limit(1)
                .get();

        if (query.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Funcionário não encontrado.')),
          );
          return;
        }

        final data = query.docs.first.data();
        // Se usar hash, compare o hash da senha digitada com o salvo
        if (data['password'] == password) {
          final employee = Employee.fromJson(data);

          // Salvar informações no SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userType', 'employee');
          await prefs.setString('userId', employee.id);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EmployeePanel(employee: employee),
            ),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Senha incorreta.')));
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  String formatPhone(String phone) {
    // Adiciona +55 se não começar com +
    if (!phone.startsWith('+')) {
      return '+55$phone';
    }
    return phone;
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
              Text(
                'Bem-vindo!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF23608D),
                ),
              ),
              SizedBox(height: 32),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Telefone',
                  prefixIcon: Icon(Icons.phone, color: Color(0xFF23608D)),
                ),
                validator: isAvalidPhone.validate,
                keyboardType: TextInputType.phone,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock, color: Color(0xFF23608D)),
                ),
                obscureText: true,
                validator: isAvalidPassword.validate,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => _loginEmployee(context),
                child: Text('Entrar'),
              ),
              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EmployeeRegisterScreen(),
                    ),
                  );
                },
                child: Text('Não tem conta? Cadastre-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
