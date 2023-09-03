import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_jordan/components/buttons.dart';
import 'package:project_jordan/components/squre_tile.dart';
import 'package:project_jordan/components/text_fileds.dart';

class SignInPage extends StatefulWidget {
  final Function()? onTap;
  const SignInPage({super.key, required this.onTap});

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
              MyButtons(ontap: signUserIn, text: "LOGIN"),
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MySqure(imagePath: "images/google.png", onTap: null),
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
    );
  }
}
