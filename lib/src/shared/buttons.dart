import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyButtons extends StatelessWidget {
  final Function()? ontap;
  final String text;
  const MyButtons({
    super.key,
    required this.ontap,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            color: const Color.fromARGB(1023, 215, 32, 16)),
        child: Center(
          child: Text(text,
              style: GoogleFonts.bebasNeue(
                fontSize: 30,
                color: Colors.white,
              )),
        ),
      ),
    );
  }
}
