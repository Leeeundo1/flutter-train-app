import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/station_list_page.dart';
import 'pages/seat_page.dart';

void main() {
  runApp(const TrainApp());
}

class TrainApp extends StatefulWidget {
  const TrainApp({super.key});

  @override
  State<TrainApp> createState() => _TrainAppState();
}

class _TrainAppState extends State<TrainApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void toggleThemeMode() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '기차 예매',
      theme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.purple,
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          centerTitle: true,
          elevation: 0,
        ),
      ),
      themeMode: _themeMode,
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(
              toggleThemeMode: toggleThemeMode,
              isDarkMode: _themeMode == ThemeMode.dark,
            ),
        '/station_list': (context) => const StationListPage(),
        '/seat': (context) => const SeatPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
