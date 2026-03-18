import 'package:flutter/material.dart';

class MySqure extends StatelessWidget {
  final String imagePath;
  final VoidCallback? onTap;
  const MySqure({super.key, required this.imagePath, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white),
          color: Colors.white,
        ),
        child: Image.asset(imagePath, height: 40),
      ),
    );
  }
}
