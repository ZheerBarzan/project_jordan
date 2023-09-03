import 'package:flutter/material.dart';
import 'package:project_jordan/pages/login_or_registation.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginOrRegistrationPages(),
    );
  }
}
