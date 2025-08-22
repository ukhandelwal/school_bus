import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const SchoolBusApp());
}

class SchoolBusApp extends StatelessWidget {
  const SchoolBusApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorPrimary = const Color(0xFF1565C0);
    final colorSecondary = const Color(0xFF00BFA6);

    return GetMaterialApp(
      title: 'School Bus Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: colorPrimary,
          primary: colorPrimary,
          secondary: colorSecondary,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 6,
          shape: CircleBorder(),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
