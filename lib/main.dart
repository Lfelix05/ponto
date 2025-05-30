import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:ponto/view/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'view/admin_panel.dart';
import 'view/employee_panel.dart';
import 'admin.dart';
import 'employee.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // Método para obter a tela inicial com base no tipo de usuário
  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userType');
    final userId = prefs.getString('userId');

    if (userType == 'admin' && userId != null) {
      // Busque os dados do admin no Firestore
      final doc =
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(userId)
              .get();
      if (doc.exists) {
        final admin = Admin.fromJson(doc.data()!);
        return AdminPanel(admin: admin);
      }
    } else if (userType == 'employee' && userId != null) {
      // Busque os dados do funcionário no Firestore
      final doc =
          await FirebaseFirestore.instance
              .collection('employees')
              .doc(userId)
              .get();
      if (doc.exists) {
        final employee = Employee.fromJson(doc.data()!);
        return EmployeePanel(employee: employee);
      }
    }
    // Se não estiver logado, vá para a tela inicial
    return const HomePage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MX Painting INC',
      theme: ThemeData(
        primaryColor: Color(0xFF23608D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF23608D),
          primary: Color(0xFF23608D),
          secondary: Color(0xFF23608D),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF23608D),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF23608D),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF23608D)),
          ),
          border: OutlineInputBorder(),
        ),
      ),
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data!;
        },
      ),
    );
  }
}
