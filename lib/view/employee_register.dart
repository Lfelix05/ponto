import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ponto/view/employee_login.dart';
import '../employee.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As senhas não coincidem')),
        );
        return;
      }
      try {
        // Verifica se já existe funcionário com esse telefone
        final query = await FirebaseFirestore.instance
            .collection('employees')
            .where('phone', isEqualTo: _phoneController.text.trim())
            .limit(1)
            .get();

        if (query.docs.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Telefone já cadastrado!')),
          );
          return;
        }
        // Cria o usuário no Firebase Authentication
        final employee = Employee(
          id: '',
          name: _nameController.text,
          phone: _phoneController.text.trim(),
          password: _passwordController.text,
          selected: false,
        );
        final docRef = await FirebaseFirestore.instance
            .collection('employees')
            .add(employee.toJson());

        // Atualize o ID no documento, se quiser salvar o id do Firestore
        await docRef.update({'id': docRef.id});

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const EmployeeLogin()),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Funcionário cadastrado com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar usuário: $e')),
        );
      }
    }
  }

  String formatPhone(String phone) {
  // Adiciona +55 se não começar com +
  if (!phone.startsWith('+')) {
    return '+55' + phone;
  }
  return phone;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro Funcionário')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome Completo',
                prefixIcon: Icon(Icons.person, color: Color(0xFF23608D)),),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu nome';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Telefone',
                prefixIcon: Icon(Icons.phone, color: Color(0xFF23608D)),),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu telefone';
                  }
                  if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                    return 'Por favor, insira um telefone válido';
                }
                  
                  return null;
                },
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha',
                prefixIcon: Icon(Icons.lock, color: Color(0xFF23608D)),),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira sua senha';
                  }
                  if (value.length < 6) {
                    return 'A senha deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _confirmPasswordController,
                decoration:
                    const InputDecoration(labelText: 'Confirmar Senha',
                    prefixIcon: Icon(Icons.lock, color: Color(0xFF23608D)),),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme sua senha';
                  }
                  if (value != _passwordController.text) {
                    return 'As senhas não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _register,
                child: const Text('Cadastrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}