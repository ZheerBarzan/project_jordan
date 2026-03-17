import 'package:flutter/material.dart';
import 'package:project_jordan/components/buttons.dart';
import 'package:project_jordan/services/auth_services.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          MyButtons(
            ontap: () => AuthService().signOut(),
            text: "Sign Out",
            color: Colors.red,
          ),
        ],
      ),
    );
  }
}
