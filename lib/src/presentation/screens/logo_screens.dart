import 'package:flutter/material.dart';

import 'package:ecomerce_app/src/presentation/screens/forms/form_screen.dart';

void main() => runApp(const LogoScreens());

class LogoScreens extends StatelessWidget {
  const LogoScreens({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FormScreen()),
        );
      }
    );
    return Scaffold(
      body: Container( 
        width: double.infinity,
        height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/logo1.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      );
  }
}