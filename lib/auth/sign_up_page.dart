import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_jordan/components/buttons.dart';
import 'package:project_jordan/components/squre_tile.dart';
import 'package:project_jordan/components/text_fileds.dart';
import 'package:project_jordan/services/auth_services.dart';

class SignUpPage extends StatefulWidget {
  final Function()? onTap;
  const SignUpPage({super.key, required this.onTap});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final passwordConfirmController = TextEditingController();
  void signUserUp() async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      if (passwordController.text == passwordConfirmController.text) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: usernameController.text,
          password: passwordController.text,
        );
      } else {
        showErrorMessege("The passwords do not match");
      }
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);

      showErrorMessege(e.code);
    }
  }

  void showErrorMessege(String error) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(error),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromARGB(1023, 20, 68, 144),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // animation
                Image.asset(
                  "images/nba.gif",
                  height: 300,
                ),

                //wellcome text
                Text('lets create an account',
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
                  height: 10,
                ),
                // password text field
                MyTextField(
                    controller: passwordController,
                    hintText: "PASSWORD",
                    obscureText: true),
                const SizedBox(
                  height: 10,
                ),
                MyTextField(
                    controller: passwordConfirmController,
                    hintText: "CONFIRM PASSWORD",
                    obscureText: true),

                // login button
                const SizedBox(
                  height: 10,
                ),
                MyButtons(
                  ontap: signUserUp,
                  text: "SIGN UP",
                  color: Colors.red,
                ),
                const SizedBox(
                  height: 10,
                ),
                // forget password
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.white,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Text(
                          'OR CONTINUE WITH',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 30,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(
                          thickness: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                // sign in with google or apple
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MySqure(
                      onTap: () => AuthService().signInWithGoogle(),
                      imagePath: "images/google.png",
                    ),
                    MySqure(imagePath: "images/apple.png", onTap: null),
                    MySqure(imagePath: "images/ms.png", onTap: null),
                  ],
                ),
                const SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ALREADY A MEMBER?',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text('SIGN IN!',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 30,
                            color: Colors.lightBlue,
                          )),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
