import 'package:flutter/material.dart';

class EmployeeCadastro extends StatefulWidget {
  const EmployeeCadastro({super.key});

  @override
  _EmployeeCadastroState createState() => _EmployeeCadastroState();
}

class _EmployeeCadastroState extends State<EmployeeCadastro> {
  final TextEditingController nomeController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Cadastro Funcionário')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: nomeController,
              decoration: InputDecoration(labelText: 'Nome do Funcionário'),
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
