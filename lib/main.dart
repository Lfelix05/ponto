import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:ponto/view/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
      home: HomePage(),
    );
  }
}
