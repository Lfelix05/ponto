import 'package:flutter/material.dart';
import 'package:ponto/cadastro_employee.dart';

class EmployeeLogin extends StatefulWidget {
  const EmployeeLogin({super.key});

  @override
  _EmployeeLoginState createState() => _EmployeeLoginState();
}

class _EmployeeLoginState extends State<EmployeeLogin> {
  final TextEditingController idController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Funcionário')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: idController,
              decoration: InputDecoration(labelText: 'ID do Funcionário'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Lógica de login do funcionário
                // Após login bem-sucedido, navegar para tela de marcação de ponto
              },
              child: Text('Entrar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EmployeeCadastro()),
                );
              },
              child: Text('Não tem cadastro? Registre-se aqui'),
            ),
          ],
        ),
      ),
    );
  }
}
