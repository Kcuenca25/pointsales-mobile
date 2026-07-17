// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/services/config_manager.dart';
import 'package:ecomerce_app/src/domain/models/odoo_config.dart';
import 'package:ecomerce_app/utils/constants.dart';
import 'dart:convert'; // Para jsonEncode/jsonDecode
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
class OnboardingStep1Screen extends StatelessWidget {
  OnboardingStep1Screen({super.key});

  final TextEditingController _domainController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Paso 1: Ingresa el dominio'),
            TextField(
              controller: _domainController,
              decoration: const InputDecoration(hintText: 'ej. midominio.tailorw.net'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_domainController.text.trim().isEmpty) return;
                // Guardar dominio en SharedPreferences
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('odoo_domain', _domainController.text.trim());
                
                // Ir al paso 2
                Navigator.pushReplacementNamed(context, '/onboarding-step2');
              },
              child: Text('Siguiente'),
            ),
          ],
        ),
      ),
    );
  }
}
