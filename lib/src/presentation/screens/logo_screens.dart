import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🎯 AÑADE ESTO

import 'package:flutter/material.dart';

class LogoScreens extends StatefulWidget {
  const LogoScreens({Key? key}) : super(key: key);

  @override
  _LogoScreensState createState() => _LogoScreensState();
  
}

class _LogoScreensState extends State<LogoScreens> {
  @override
  void initState() {
    super.initState();
    print('🎯 LogoScreens: Mostrando logo...');
    
     Future.delayed(const Duration(seconds: 2), () {
    if (mounted) {
      _navigateToNextScreen();
    }
  });
  }
  void _navigateToNextScreen() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    final prefs = await SharedPreferences.getInstance();
    final hasDomain = prefs.getString('odoo_domain') != null;
    final hasDatabase = prefs.getString('odoo_database') != null;
    final hasCredentials = prefs.getInt('current_uid') != null;
    
    String nextRoute;
    if (!hasDomain) {
      nextRoute = '/onboarding-step1';
    } else if (!hasDatabase) {
      nextRoute = '/onboarding-step2';
    } else if (!hasCredentials) {
      nextRoute = '/credentials';
    } else {
      nextRoute = '/select-company';
    }
    
    print('🎯 LogoScreens: Navegando a $nextRoute');
    Navigator.of(context).pushReplacementNamed(nextRoute);
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo1.png', height: 150),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Iniciando aplicación...',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
