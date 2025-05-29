import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../admin.dart';
import 'admin_login.dart';
import '../utils/validator.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  _AdminRegisterScreenState createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('As senhas não coincidem')));
        return;
      }

      try {
        // Cria o usuário no Firebase Authentication
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text,
              password: _passwordController.text,
            );

        // Salva os dados no Firestore
        final admin = Admin(
          id: userCredential.user!.uid,
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );

        await FirebaseFirestore.instance
            .collection('admins')
            .doc(admin.id)
            .set(admin.toJson());

        // Redireciona para a tela de login após o registro
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Administrador cadastrado com sucesso!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao cadastrar administrador: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro de Administrador')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Preencha os dados para se cadastrar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 32),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nome',
                prefixIcon: Icon(Icons.person)),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira seu nome';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email',
                prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
                validator: isAvalidEmail.validate,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Senha',
                prefixIcon: Icon(Icons.lock)),
                obscureText: true,
                validator: isAvalidPassword.validate,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: 'Confirmar Senha',
                prefixIcon: Icon(Icons.lock)),
                validator: (value) => confirmPassword.validate(
                  value ?? '',
                  _passwordController.text,
                ),
                obscureText: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _register, child: Text('Cadastrar')),
            
              
                ],
          ),
        ),
      ),
    );
  }
}
