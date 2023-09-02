import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_jordan/components/buttons.dart';
import 'package:project_jordan/components/text_fileds.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final usernameController = TextEditingController();

  final passwordController = TextEditingController();
  void signUserIn() {}
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
            const SizedBox(
              height: 10,
            ),

            // email text field
            MyTextField(
                controller: usernameController,
                hintText: "USER NAME",
                obscureText: false),
            const SizedBox(
              height: 20,
            ),
            // password text field
            MyTextField(
                controller: passwordController,
                hintText: "PASSWORD",
                obscureText: true),

            // login button
            const SizedBox(
              height: 20,
            ),
            MyButtons(ontap: signUserIn, text: "LOGIN"),

            // forget password

            // sign in with google or apple
          ]),
        ),
      ),
    );
  }
}
