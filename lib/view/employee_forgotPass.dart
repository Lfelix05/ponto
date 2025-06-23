import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ponto/utils/validator.dart';

class EmployeeForgotPassword extends StatefulWidget {
  const EmployeeForgotPassword({super.key});

  @override
  State<EmployeeForgotPassword> createState() => _EmployeeForgotPasswordState();
}

class _EmployeeForgotPasswordState extends State<EmployeeForgotPassword> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmSenhaController = TextEditingController();

  bool _codigoGerado = false;
  bool _codigoValidado = false;

  Future<void> _gerarCodigo(String phone) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('employees')
              .where('phone', isEqualTo: phone)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Número de telefone não encontrado.')),
        );
        return;
      }

      final docId = query.docs.first.id;

      // Gera um código de 6 dígitos
      final codigo =
          (100000 + (DateTime.now().millisecondsSinceEpoch % 900000))
              .toString();

      // Salva o código no Firestore
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(docId)
          .update({'verificationCode': codigo});

      setState(() => _codigoGerado = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de verificação gerado!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao gerar código: $e')));
    }
  }

  Future<void> _validarCodigo(String phone, String codigoDigitado) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('employees')
              .where('phone', isEqualTo: phone)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Número de telefone não encontrado.')),
        );
        return;
      }

      final data = query.docs.first.data();
      final codigoSalvo = data['verificationCode'];

      if (codigoSalvo == codigoDigitado) {
        setState(() => _codigoValidado = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código validado com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Código inválido.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao validar código: $e')));
    }
  }

  Future<void> _redefinirSenha(String phone, String novaSenha) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection('employees')
              .where('phone', isEqualTo: phone)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Número de telefone não encontrado.')),
        );
        return;
      }
      if (novaSenha != _confirmSenhaController.text.trim()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As senhas não coincidem.')),
        );
        return;
      } else {
        final docId = query.docs.first.id;

        // Hash da senha usando SHA-256
        final bytes = utf8.encode(novaSenha);
        final hashedPassword = sha256.convert(bytes).toString();

        // Atualiza a senha no Firestore
        await FirebaseFirestore.instance
            .collection('employees')
            .doc(docId)
            .update({'password': hashedPassword});

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Senha redefinida com sucesso!')),
        );

        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao redefinir senha: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 195, 230, 255),
      appBar: AppBar(title: const Text('Redefinir Senha')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_reset, size: 60, color: Colors.blue),
                    const SizedBox(height: 16),
                    if (!_codigoGerado) ...[
                      const Text(
                        'Digite seu número de telefone para receber um código de verificação.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _phoneController,
                        validator: isAvalidPhone.validate,
                        decoration: const InputDecoration(
                          labelText: 'Telefone',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:
                            () => _gerarCodigo(_phoneController.text.trim()),
                        child: const Text('Gerar Código'),
                      ),
                    ] else if (!_codigoValidado) ...[
                      const Text(
                        'Digite o código de verificação, solicite-o ao administrador.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _codeController,
                        decoration: const InputDecoration(
                          labelText: 'Código de Verificação',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:
                            () => _validarCodigo(
                              _phoneController.text.trim(),
                              _codeController.text.trim(),
                            ),
                        child: const Text('Validar Código'),
                      ),
                    ] else ...[
                      const Text(
                        'Digite sua nova senha.',
                        textAlign: TextAlign.center,
                      ),
                      TextFormField(
                        controller: _senhaController,
                        validator: isAvalidPassword.validate,
                        decoration: const InputDecoration(
                          labelText: 'Nova Senha',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _confirmSenhaController,
                        validator: isAvalidPassword.validate,
                        decoration: const InputDecoration(
                          labelText: 'Confirme a Senha',
                          border: OutlineInputBorder(),
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed:
                            () => _redefinirSenha(
                              _phoneController.text.trim(),
                              _senhaController.text.trim(),
                            ),
                        child: const Text('Redefinir Senha'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
