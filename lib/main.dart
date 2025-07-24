import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'package:ponto/view/home.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'l10n/localization.dart';
import 'view/admin_login.dart';
import 'view/admin_panel.dart';
import 'view/employee_panel.dart';
import 'admin.dart';
import 'employee.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:workmanager/workmanager.dart';
import 'utils/notifications.dart';
import 'utils/validator.dart';
import 'package:flutter/foundation.dart'; // Para verificar se está na Web
import 'package:flutter/services.dart';

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
        // Sem contexto aqui, a função usará textos padrão
      );
    }

    return Future.value(true);
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializa as mensagens de validação
  await ValidatorMessages.initialize();

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

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    ]).then((_) {
      runApp(
        ChangeNotifierProvider(
          create: (_) => LocalizationProvider(),
          child: const MyApp(),
        ),
      );
    });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Future<Widget> _getInitialScreen() async {
    if (kIsWeb) {
      // Redireciona diretamente para a tela de login do administrador na Web
      return const LoginScreen();
    }

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
    final localizationProvider = Provider.of<LocalizationProvider>(context);

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return snapshot.data ?? const HomePage();
        },
      ),

      // Configuração da internacionalização
      locale: localizationProvider.locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt'), // Português
        Locale('en'), // Inglês
      ],
    );
  }
}
