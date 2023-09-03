import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:project_jordan/components/buttons.dart';
import 'package:project_jordan/components/squre_tile.dart';
import 'package:project_jordan/components/text_fileds.dart';

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
              Image.asset(
                "images/nba.gif",
                height: 300,
              ),

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
              MyButtons(ontap: signUserIn, text: "LOGIN"),
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MySqure(imagePath: "images/google.png", onTap: null),
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
    );
  }
}
