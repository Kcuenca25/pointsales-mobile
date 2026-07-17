// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
//import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
//import 'package:ecomerce_app/src/services/config_manager.dart';
//import 'package:ecomerce_app/src/domain/models/odoo_config.dart';
//import 'package:ecomerce_app/utils/constants.dart';
//import 'dart:convert'; // Para jsonEncode/jsonDecode
//import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class OnboardingStep2Screen extends StatefulWidget {
  const OnboardingStep2Screen({super.key});

  @override
  _OnboardingStep2ScreenState createState() => _OnboardingStep2ScreenState();
}

class _OnboardingStep2ScreenState extends State<OnboardingStep2Screen> {
  String? _detectedDatabase;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _detectDatabase();
  }

  Future<void> _detectDatabase() async {
    setState(() => _isLoading = true);
    
    // Obtener dominio guardado
    final prefs = await SharedPreferences.getInstance();
    final domain = prefs.getString('odoo_domain') ?? '';
    
    try {
      // Buscar bases de datos disponibles
      // Si hay solo una, detectarla automáticamente
      // Si hay múltiples, mostrar selector
      
      // Por ahora, asumir pointsales-v18
      _detectedDatabase = 'pointsales-v18';
      
      // Guardar BD
      await prefs.setString('odoo_database', _detectedDatabase!);
      
    } catch (e) {
      print('Error detectando BD: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading 
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Paso 2: Base de datos detectada'),
                  Text('$_detectedDatabase'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/credentials');
                    },
                    child: Text('Continuar'),
                  ),
                ],
              ),
      ),
    );
  }
}
