import 'package:flutter/material.dart';
import 'screens/tests_screen.dart';   // ← مهم جداً

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'معمل الفكرة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF81D4FA), // أزرق فاتح زي ما طلبتي
        ),
        useMaterial3: true,
        fontFamily: 'Cairo', // لو عندك خط القاهرة
      ),
      home: const TestsScreen(),   // ← هنا بنغير الشاشة الرئيسية
    );
  }
}