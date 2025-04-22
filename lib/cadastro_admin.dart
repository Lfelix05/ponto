import 'package:flutter/material.dart';

class AdminCadastro extends StatefulWidget {
  const AdminCadastro({super.key});

  @override
  _AdminCadastroState createState() => _AdminCadastroState();
}

class _AdminCadastroState extends State<AdminCadastro> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro Admin')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome do Administrador'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(labelText: 'Número de telefone'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: () {}, child: Text('Entrar')),
          ],
        ),
      ),
    );
  }
}
