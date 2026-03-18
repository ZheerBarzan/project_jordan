import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:project_jordan/auth/auth_page.dart';
import 'package:project_jordan/theme/app_theme.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final Widget home;

  const MyApp({super.key, this.home = const Authpage()});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: home,
    );
  }
}
