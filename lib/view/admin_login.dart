import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ponto/view/admin_forgotPass.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../admin.dart';
import 'admin_panel.dart';
import 'admin_panelWeb.dart';
import 'admin_register.dart';
import '../utils/validator.dart';
import 'package:flutter/foundation.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();

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

          if (kIsWeb) {
            // Redireciona diretamente para a tela de painel do administrador na Web
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminPanelWeb(admin: admin)),
            );
          } else {
            // Para dispositivos móveis, redireciona para o painel do administrador
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminPanel(admin: admin)),
            );
          }
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
      backgroundColor: const Color.fromARGB(255, 195, 230, 255),
      appBar: AppBar(title: const Text('Login Administrador')),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ), // Limita a largura máxima para Web
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 36,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Ícone grande para reforçar o contexto
                      Icon(
                        Icons.admin_panel_settings,
                        size: 60,
                        color: Colors.blue[700],
                      ),
                      const SizedBox(height: 16),
                      // Título
                      Text(
                        'Bem-vindo!',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtítulo
                      Text(
                        'Acesse sua conta de administrador',
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Campo de email
                      TextFormField(
                        controller: _loginController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(
                            Icons.email,
                            color: Color(0xFF23608D),
                          ),
                        ),
                        validator: isAvalidEmail.validate,
                      ),
                      const SizedBox(height: 16),
                      // Campo de senha
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Color(0xFF23608D),
                          ),
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
                                  builder: (context) => AdminForgotPassword(),
                                ),
                              );
                            },
                            child: const Text(
                              'Esqueci minha senha',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Botão de login
                      ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: const Text(
                          'Entrar',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Botão para cadastro
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AdminRegisterScreen(),
                            ),
                          );
                        },
                        child: const Text('Não tem conta? Cadastre-se'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
