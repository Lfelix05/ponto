import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:ponto/view/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'view/admin_login.dart';
import 'view/admin_panel.dart';
import 'view/employee_panel.dart';
import 'admin.dart';
import 'employee.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'utils/notifications.dart';
import 'package:flutter/foundation.dart'; // Para verificar se está na Web

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      await Firebase.initializeApp();
    } catch (_) {}

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    final androidPlugin =
        flutterLocalNotificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    await androidPlugin?.createNotificationChannel(
      AndroidNotificationChannel(
        'ponto_channel',
        'Ponto Notificações',
        description: 'Notificações do app de ponto',
        importance: Importance.max,
      ),
    );

    final employeeId = inputData?['employeeId'] as String?;
    final checkInTime = inputData?['checkInTime'] as String?;

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

  // Inicialize o WorkManager apenas para plataformas móveis
  if (!kIsWeb) {
    await Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  }

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

  final androidPlugin =
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
  await androidPlugin?.createNotificationChannel(
    AndroidNotificationChannel(
      'ponto_channel',
      'Ponto Notificações',
      description: 'Notificações do app de ponto',
      importance: Importance.max,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    if (kIsWeb) {
      // Redireciona diretamente para a tela de login do administrador na Web
      return const LoginScreen();
    }

    print('Carregando tela inicial...');
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString('userType');
    final userId = prefs.getString('userId');

    print('userType: $userType, userId: $userId');

    if (userType == 'admin' && userId != null) {
      final doc =
          await FirebaseFirestore.instance
              .collection('admins')
              .doc(userId)
              .get();
      if (doc.exists) {
        final admin = Admin.fromJson(doc.data()!);
        print('Admin encontrado: ${admin.name}');
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
        print('Funcionário encontrado: ${employee.name}');
        return EmployeePanel(employee: employee);
      }
    }
    print('Redirecionando para HomePage...');
    return const HomePage();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ponto',
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
