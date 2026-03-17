import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_jordan/components/buttons.dart';
import 'package:project_jordan/components/squre_tile.dart';
import 'package:project_jordan/components/text_fileds.dart';
import 'package:project_jordan/services/auth_services.dart';

class SignInPage extends StatefulWidget {
  final VoidCallback? onTap;
  const SignInPage({super.key, this.onTap});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final AuthService _authService = AuthService();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  Future<void> signUserIn() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      await _authService.signInWithEmail(
        email: usernameController.text,
        password: passwordController.text,
      );

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();

      final String message = error.toString();
      if (message.contains("user-not-found")) {
        showErrorMessege("Wrong Email or UserName!!✌️😎");
      } else if (message.contains("wrong-password")) {
        showErrorMessege("your password is wrong!!✌️😎");
      } else {
        showErrorMessege(message);
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _authService.signInWithGoogle();
    } catch (error) {
      if (!mounted) {
        return;
      }
      showErrorMessege(error.toString());
    }
  }

  void showErrorMessege(String error) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(title: Text(error));
      },
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
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
                Image.asset("images/nba.gif"),

                //wellcome text
                Text(
                  'Welcome to NBA',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),

                // email text field
                MyTextField(
                  controller: usernameController,
                  hintText: "USER NAME",
                  obscureText: false,
                ),
                const SizedBox(height: 20),
                // password text field
                MyTextField(
                  controller: passwordController,
                  hintText: "PASSWORD",
                  obscureText: true,
                ),

                // login button
                const SizedBox(height: 20),
                MyButtons(ontap: signUserIn, text: "LOG IN", color: Colors.red),
                const SizedBox(height: 20),
                // forget password
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Divider(thickness: 0.5, color: Colors.white),
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
                        child: Divider(thickness: 0.5, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // sign in with google or apple
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    MySqure(
                      onTap: signInWithGoogle,
                      imagePath: "images/google.png",
                    ),
                    const MySqure(imagePath: "images/apple.png", onTap: null),
                    const MySqure(imagePath: "images/ms.png", onTap: null),
                  ],
                ),
                const SizedBox(height: 15),
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
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Text(
                        'Register now!',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 30,
                          color: Colors.lightBlue,
                        ),
                      ),
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
