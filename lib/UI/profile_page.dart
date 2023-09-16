import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:project_jordan/components/buttons.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void signOut() {
    FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        MyButtons(ontap: signOut, text: "Sign Out", color: Colors.red)
      ],
    ));
  }
}
