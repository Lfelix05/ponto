import 'package:flutter/material.dart';
import 'package:ponto/cadastro_admin.dart';
import 'admin_panel.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  void login() {
    if (usernameController.text == "max123" && passwordController.text == "1234") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminPanel()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login inválido!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login do Administrador")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: "Usuário")),
            TextField(controller: passwordController, decoration: InputDecoration(labelText: "Senha"), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: Text("Entrar")),
            SizedBox(height: 50),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminCadastro()),
                );
                },
              child: Text(
                'Primeiro acesso? Cadastre-se aqui',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
      
    );
    
  }
}
