import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ponto/view/admin_login.dart';
import 'package:ponto/l10n/localization.dart';
import 'employee_login.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 195, 230, 255),
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.appTitle),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.language, size: 26),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return Consumer<LocalizationProvider>(
                    builder: (context, provider, child) {
                      final currentLocale = provider.locale.languageCode;

                      return AlertDialog(
                        title: Text(
                          AppLocalizations.of(context)!.languageSettings,
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Opção para Português
                            RadioListTile<String>(
                              title: Text('Português'),
                              value: 'pt',
                              groupValue: currentLocale,
                              onChanged: (value) {
                                if (value != null) {
                                  provider.setLocale(Locale(value));
                                  Navigator.pop(context);
                                }
                              },
                            ),

                            // Opção para Inglês
                            RadioListTile<String>(
                              title: Text('English'),
                              value: 'en',
                              groupValue: currentLocale,
                              onChanged: (value) {
                                if (value != null) {
                                  provider.setLocale(Locale(value));
                                  Navigator.pop(context);
                                }
                              },
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(AppLocalizations.of(context)!.close),
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            margin: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset('assets/logo.png', height: 100),
                  SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.loginTitle,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 48),
                  Text(
                    AppLocalizations.of(context)!.selectlogin,
                    style: TextStyle(fontSize: 15, color: Colors.grey[700]),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EmployeeLogin(),
                        ),
                      );
                    },
                    icon: Icon(Icons.badge, size: 26),
                    label: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 8,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.employeeLoginSubtitle,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[800],
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                  ),
                  SizedBox(height: 18),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    icon: Icon(Icons.admin_panel_settings, size: 26),
                    label: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 8,
                      ),
                      child: Text(
                        AppLocalizations.of(context)!.adminLoginSubtitle,
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
