import 'package:flutter/material.dart';
import 'package:project_jordan/pages/sign_in_page.dart';
import 'package:project_jordan/pages/sign_up_page.dart';

class LoginOrRegistrationPages extends StatefulWidget {
  const LoginOrRegistrationPages({super.key});

  @override
  State<LoginOrRegistrationPages> createState() =>
      _LoginOrRegistrationPagesState();
}

class _LoginOrRegistrationPagesState extends State<LoginOrRegistrationPages> {
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage == true) {
      return SignInPage(onTap: togglePages);
    } else {
      return SignUpPage(onTap: togglePages);
    }
  }
}
