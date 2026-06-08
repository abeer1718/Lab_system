import 'package:flutter/material.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/tests_screen.dart';   // ← مهم جداً

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة قاعدة البيانات للويندوز
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
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