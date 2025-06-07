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
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'utils/notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Inicializa o plugin de notificações no background
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final employeeId = inputData?['employeeId'] as String?;
    final checkInTime = inputData?['checkInTime'] as String?;
    print('WorkManager callback disparado!');
    print('WorkManager executado para $employeeId às $checkInTime');
    if (employeeId != null) {
      await scheduleCheckInReminder(
        employeeId: employeeId,
        checkInTime: checkInTime,
      );
    }
    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicialize o WorkManager para background tasks
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // Coloque false em produção
  );

  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  final InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.requestNotificationsPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userType');
    final userId = prefs.getString('userId');

    if (userType == 'admin' && userId != null) {
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
