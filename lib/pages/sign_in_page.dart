import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_jordan/components/buttons.dart';
import 'package:project_jordan/components/squre_tile.dart';
import 'package:project_jordan/components/text_fileds.dart';
import 'package:project_jordan/services/auth_services.dart';

class SignInPage extends StatefulWidget {
  final Function()? onTap;
  const SignInPage({super.key, this.onTap});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final usernameController = TextEditingController();

  final passwordController = TextEditingController();
  void signUserIn() async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: usernameController.text,
        password: passwordController.text,
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context);

      // we can also use one method for the code below using this code
      // showerorrmessege(e.code);
      // and make the chiled of the method text(messege)

      if (e.code == "user-not-found") {
        showErrorMessege("Wrong Email or UserName!!✌️😎");
      } else if (e.code == "wrong-password") {
        showErrorMessege("your password is wrong!!✌️😎");
      }
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          backgroundColor: const Color.fromARGB(1023, 20, 68, 144),
          body: Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
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
                  MyButtons(ontap: signUserIn, text: "LOG IN"),
                  const SizedBox(
                    height: 20,
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
                    height: 15,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Not a Member?',
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
                        child: Text('Register now!',
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
      ),
    );
  }
}
