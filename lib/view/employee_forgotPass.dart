import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ponto/utils/validator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
  final _formKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  final _codeFormKey = GlobalKey<FormState>();

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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.phoneNumberNotFound)));
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

      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.verificationCodeGenerated)));
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorGeneratingCode(e.toString()))),
      );
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
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.phoneNumberNotFound)));
        return;
      }

      final data = query.docs.first.data();
      final codigoSalvo = data['verificationCode'];

      if (codigoSalvo == codigoDigitado) {
        setState(() => _codigoValidado = true);
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.codeValidatedSuccessfully)));
      } else {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.invalidCode)));
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorValidatingCode(e.toString()))),
      );
    }
  }

  Future<void> _redefinirSenha(String phone, String novaSenha) async {
    final l10n = AppLocalizations.of(context)!;

    // Validar senha
    final senhaError = isAvalidPassword.validateWithContext(novaSenha, context);
    if (senhaError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(senhaError)));
      return;
    }

    // Validar confirmação de senha
    final confirmSenhaError = confirmPassword.validateWithContext(
      novaSenha,
      _confirmSenhaController.text.trim(),
      context,
    );
    if (confirmSenhaError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(confirmSenhaError)));
      return;
    }

    try {
      final query =
          await FirebaseFirestore.instance
              .collection('employees')
              .where('phone', isEqualTo: phone)
              .limit(1)
              .get();

      if (query.docs.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.phoneNumberNotFound)));
        return;
      }

      final docId = query.docs.first.id;

      // Hash da senha usando SHA-256
      final bytes = utf8.encode(novaSenha);
      final hashedPassword = sha256.convert(bytes).toString();

      // Atualiza a senha no Firestore
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(docId)
          .update({'password': hashedPassword});

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.passwordResetSuccess)));

      Navigator.pop(context);
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorResettingPassword(e.toString()))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 195, 230, 255),
      appBar: AppBar(title: Text(l10n.resetpassword)),
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
                      Text(
                        l10n.enterPhoneForVerificationCode,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _phoneFormKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _phoneController,
                              validator:
                                  (value) => isAvalidPhone.validateWithContext(
                                    value,
                                    context,
                                  ),
                              decoration: InputDecoration(
                                labelText: l10n.phone,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                if (_phoneFormKey.currentState!.validate()) {
                                  _gerarCodigo(_phoneController.text.trim());
                                }
                              },
                              child: Text(l10n.generateCode),
                            ),
                          ],
                        ),
                      ),
                    ] else if (!_codigoValidado) ...[
                      Text(
                        l10n.enterVerificationCodeFromAdmin,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Form(
                        key: _codeFormKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _codeController,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return l10n.enterVerificationCodeFromAdmin;
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: l10n.verificationCodeLabel,
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                if (_codeFormKey.currentState!.validate()) {
                                  _validarCodigo(
                                    _phoneController.text.trim(),
                                    _codeController.text.trim(),
                                  );
                                }
                              },
                              child: Text(l10n.validateCode),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Text(l10n.enterNewPassword, textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _senhaController,
                              validator:
                                  (value) => isAvalidPassword
                                      .validateWithContext(value, context),
                              decoration: InputDecoration(
                                labelText: l10n.newPassword,
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 10),
                            TextFormField(
                              controller: _confirmSenhaController,
                              validator:
                                  (value) =>
                                      confirmPassword.validateWithContext(
                                        _senhaController.text.trim(),
                                        value,
                                        context,
                                      ),
                              decoration: InputDecoration(
                                labelText: l10n.confirmPassword,
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  _redefinirSenha(
                                    _phoneController.text.trim(),
                                    _senhaController.text.trim(),
                                  );
                                }
                              },
                              child: Text(l10n.resetpassword),
                            ),
                          ],
                        ),
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
