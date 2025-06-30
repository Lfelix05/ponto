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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context)!;

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Autentica com Firebase Auth
        final userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
              email: _loginController.text.trim(),
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
              MaterialPageRoute(
                builder: (context) => AdminPanelWeb(admin: admin),
              ),
            );
          } else {
            // Para dispositivos móveis, redireciona para o painel do administrador
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => AdminPanel(admin: admin)),
            );
          }
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.loginError)));
        }
      } on FirebaseAuthException catch (e) {
        String errorMessage;

        // Traduzir mensagens de erro comuns do Firebase Auth
        switch (e.code) {
          case 'user-not-found':
            errorMessage = l10n.userNotFound;
            break;
          case 'wrong-password':
            errorMessage = l10n.incorrectPassword;
            break;
          case 'invalid-email':
            errorMessage = l10n.invalidEmail;
            break;
          case 'user-disabled':
            errorMessage = l10n.userDisabled;
            break;
          case 'too-many-requests':
            errorMessage = l10n.tooManyRequests;
            break;
          default:
            errorMessage = l10n.authError(e.message ?? e.code);
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      } catch (e) {
        // Captura outros erros não relacionados à autenticação
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString()))),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 195, 230, 255),
      appBar: AppBar(title: Text(l10n.adminloginTitle)),
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
                        l10n.loginTitle,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Subtítulo
                      Text(
                        l10n.logintext,
                        style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      // Campo de email
                      TextFormField(
                        controller: _loginController,
                        decoration: InputDecoration(
                          labelText: l10n.email,
                          prefixIcon: const Icon(
                            Icons.email,
                            color: Color(0xFF23608D),
                          ),
                        ),
                        // Usando o método com internacionalização
                        validator:
                            (value) => isAvalidEmail.validateWithContext(
                              value,
                              context,
                            ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      // Campo de senha
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: l10n.password,
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Color(0xFF23608D),
                          ),
                        ),
                        obscureText: true,
                        // Usando o método com internacionalização
                        validator:
                            (value) => isAvalidPassword.validateWithContext(
                              value,
                              context,
                            ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => const AdminForgotPassword(),
                                ),
                              );
                            },
                            child: Text(
                              l10n.forgotPassword,
                              style: const TextStyle(
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
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                )
                                : Text(
                                  l10n.login,
                                  style: const TextStyle(fontSize: 18),
                                ),
                      ),
                      const SizedBox(height: 20),
                      // Botão para cadastro
                      TextButton(
                        onPressed:
                            _isLoading
                                ? null
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const AdminRegisterScreen(),
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
      ),
    );
  }
}
