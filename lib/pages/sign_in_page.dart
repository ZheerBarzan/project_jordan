import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(1023, 20, 68, 144),
        body: Center(
          child: Column(children: [
            // animation
            Image.asset("images/nba.gif"),

            //wellcome text
            Text('Welcome to NBA',
                style: GoogleFonts.bebasNeue(
                  fontSize: 30,
                  color: Colors.white,
                )),

            // email text field

            // password text field

            // login button

            // forget password

            // sign in with google or apple
          ]),
        ),
      ),
    );
  }
}
