import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../admin.dart';
import 'admin_login.dart';
import '../utils/validator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.passwordfail)),
        );
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
          SnackBar(content: Text(AppLocalizations.of(context)!.registersucces)),
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
      backgroundColor: const Color.fromARGB(255, 195, 230, 255),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.adminregisterTitle),
      ),
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
                        'Cadastro de Administrador',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtítulo
                      Text(
                        AppLocalizations.of(context)!.registerText,
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Campo de nome
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.fullName,
                          prefixIcon: Icon(
                            Icons.person,
                            color: Color(0xFF23608D),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira seu nome';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Campo de email
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(
                            Icons.email,
                            color: Color(0xFF23608D),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: isAvalidEmail.validate,
                      ),
                      const SizedBox(height: 16),
                      // Campo de senha
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.password,
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Color(0xFF23608D),
                          ),
                        ),
                        obscureText: true,
                        validator: isAvalidPassword.validate,
                      ),
                      const SizedBox(height: 16),
                      // Campo de confirmação de senha
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText:
                              AppLocalizations.of(context)!.confirmPassword,
                          prefixIcon: Icon(
                            Icons.lock,
                            color: Color(0xFF23608D),
                          ),
                        ),
                        validator:
                            (value) => confirmPassword.validateWithContext(
                              _passwordController.text,
                              value,
                              context,
                            ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 24),
                      // Botão de cadastro
                      ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.register,
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
      ),
    );
  }
}
