import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin.dart';
import 'admin_panel.dart';
import 'admin_register.dart';
import '../utils/validator.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>(); // Controle do formulário
  final _loginController =
      TextEditingController(); // Controlador para o campo de email
  final _passwordController =
      TextEditingController(); // Controlador para o campo de senha

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Autentica com Firebase Auth
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _loginController.text,
              password: _passwordController.text,
            );

        // Busca os dados do admin no Firestore usando o UID do usuário autenticado
        final uid = userCredential.user!.uid;
        final doc =
            await FirebaseFirestore.instance
                .collection('admins')
                .doc(uid)
                .get();

        if (doc.exists) {
          final admin = Admin.fromJson(doc.data()!);

          // Salva informações no SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userType', 'admin');
          await prefs.setString('userId', admin.id);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => AdminPanel(admin: admin)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Admin não encontrado no banco de dados.')),
          );
        }
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro de autenticação: ${e.message}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
                controller: _loginController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email, color: Color(0xFF23608D)),
                ),
                validator: isAvalidEmail.validate,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Senha',
                  prefixIcon: Icon(Icons.lock, color: Color(0xFF23608D)),
                ),
                obscureText: true,
                validator: isAvalidPassword.validate,
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: _login, child: Text('Entrar')),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AdminRegisterScreen(),
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
