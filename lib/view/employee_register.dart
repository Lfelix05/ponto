import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ponto/utils/validator.dart';
import 'package:ponto/view/employee_login.dart';
import '../employee.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EmployeeRegisterScreen extends StatefulWidget {
  const EmployeeRegisterScreen({super.key});

  @override
  State<EmployeeRegisterScreen> createState() => _EmployeeRegisterScreen();
}

class _EmployeeRegisterScreen extends State<EmployeeRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.passwordfail)));
        return;
      }
      try {
        final query =
            await FirebaseFirestore.instance
                .collection('employees')
                .where('phone', isEqualTo: _phoneController.text.trim())
                .limit(1)
                .get();

        if (query.docs.isNotEmpty) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.phoneAlreadyRegistered)));
          return;
        }
        final employee = Employee(
          id: '',
          name: _nameController.text,
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          selected: false,
          checkIn_Time: '',
          verificationCode: '',
        );
        final docRef = await FirebaseFirestore.instance
            .collection('employees')
            .add(employee.toJson());

        await docRef.update({'id': docRef.id});

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmployeeLogin()),
        );
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.registersucces)));
      } catch (e) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorRegisteringUser(e.toString()))),
        );
      }
    }
  }

  String formatPhone(String phone) {
    if (!phone.startsWith('+')) {
      return '+55' + phone;
    }
    return phone;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 195, 230, 255),
      appBar: AppBar(
        title: Text(l10n.employeeregisterTitle),
        centerTitle: true,
        elevation: 0,
      ),
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
                    Icon(Icons.person_add, size: 60, color: Colors.blue[700]),
                    SizedBox(height: 16),
                    Text(
                      l10n.employeeregisterTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      l10n.registerText,
                      style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: l10n.fullName,
                        prefixIcon: Icon(
                          Icons.person,
                          color: Color(0xFF23608D),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.pleaseEnterName;
                        }
                        if (value.length < 3) {
                          return l10n.nameMinLength;
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: l10n.phone,
                        prefixIcon: Icon(Icons.phone, color: Color(0xFF23608D)),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: isAvalidPhone.validate,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        prefixIcon: Icon(Icons.lock, color: Color(0xFF23608D)),
                      ),
                      obscureText: true,
                      validator: isAvalidPassword.validate,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmPasswordController,
                      decoration: InputDecoration(
                        labelText: l10n.confirmPassword,
                        prefixIcon: Icon(Icons.lock, color: Color(0xFF23608D)),
                      ),
                      obscureText: true,
                      validator:
                          (value) => confirmPassword.validate(
                            value ?? '',
                            _passwordController.text,
                          ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 48),
                        backgroundColor: Colors.blue[800],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        l10n.register,
                        style: TextStyle(fontSize: 18),
                      ),
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
