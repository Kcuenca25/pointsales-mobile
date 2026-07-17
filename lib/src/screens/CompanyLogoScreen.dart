// lib/screens/company_logo_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';



class CompanyLogoScreen extends StatefulWidget {
  const CompanyLogoScreen({super.key});

  @override
  _CompanyLogoScreenState createState() => _CompanyLogoScreenState();
}

class _CompanyLogoScreenState extends State<CompanyLogoScreen> {
  String? _companyName;

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  Future<void> _loadCompanyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    _companyName = prefs.getString('selected_company_name') ?? 'Mi Empresa';
    
    print('🎯 CompanyLogoScreen: Empresa - $_companyName');
    
    // 🎯 IMPORTANTE: Después de mostrar logo, ir DIRECTAMENTE al home
    Future.delayed(const Duration(seconds: 2), () {
      print('🎯 CompanyLogoScreen: Redirigiendo a HomeScreen');
      Navigator.pushReplacementNamed(context, '/home_screen');
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
            if (_companyName != null) ...[
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 60,
              ),
              const SizedBox(height: 20),
              Text(
                '¡Bienvenido!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _companyName!,
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.grey,
                ),
              ),
            ],
            const SizedBox(height: 30),
            const CircularProgressIndicator(color: Colors.deepPurple),
            const SizedBox(height: 20),
            const Text(
              'Abriendo aplicación...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
