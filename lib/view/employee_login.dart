import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ponto/utils/validator.dart';
import 'package:ponto/view/employee_panel.dart';
import 'package:ponto/view/employee_register.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../employee.dart';
import 'employee_forgotPass.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

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
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.employeeNotFound)));
          return;
        }

        final data = query.docs.first.data();

        // Converter a senha digitada em hash para comparar
        final bytes = utf8.encode(password);
        final hashedPassword = sha256.convert(bytes).toString();

        // Comparar os hashes
        if (data['password'] == hashedPassword) {
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
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.incorrectPassword)));
        }
      } catch (e) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString()))),
        );
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
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 195, 230, 255),
      appBar: AppBar(title: Text(l10n.employeeloginTitle)),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.badge, size: 60, color: Colors.blue[700]),
                    SizedBox(height: 16),
                    Text(
                      l10n.loginTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      l10n.logintext,
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 32),
                    TextFormField(
                      controller: phoneController,
                      decoration: InputDecoration(
                        labelText: l10n.phone,
                        prefixIcon: Icon(Icons.phone, color: Color(0xFF23608D)),
                      ),
                      validator: isAvalidPhone.validate,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: Icon(Icons.lock, color: Color(0xFF23608D)),
                      ),
                      obscureText: true,
                      validator: isAvalidPassword.validate,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EmployeeForgotPassword(),
                              ),
                            );
                          },
                          child: Text(l10n.forgotPassword),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => _loginEmployee(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Text(l10n.login, style: TextStyle(fontSize: 18)),
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
                      child: Text(l10n.noAccount),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
