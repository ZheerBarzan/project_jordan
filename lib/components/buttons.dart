import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyButtons extends StatelessWidget {
  final Function()? ontap;
  final String text;
  final Color color;
  const MyButtons({
    super.key,
    required this.ontap,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ontap,
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15), color: color),
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
