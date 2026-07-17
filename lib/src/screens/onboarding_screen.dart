// lib/screens/onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/services/config_manager.dart';
import 'package:ecomerce_app/src/domain/models/odoo_config.dart';
import 'package:ecomerce_app/utils/constants.dart';
import 'dart:convert'; // Para jsonEncode/jsonDecode
import 'package:http/http.dart' as http;
// onboarding_screen.dart - VERSIÓN SIMPLIFICADA (SIN BUSCAR BD)
// onboarding_screen.dart - VERSIÓN CON BD MANUAL

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _domainController = TextEditingController();
  final _dbNameController = TextEditingController(text: 'pointsales-v18'); // ← MANTENEMOS
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  
  bool _isLoading = false;
  String _errorMessage = '';
  String _statusMessage = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header con logo
              const SizedBox(height: 40),
              Image.asset(
                'assets/images/logo1.png',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text(
                'Configurar Conexión Odoo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Ingresa los datos de tu instancia Odoo',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Formulario COMPLETO (4 campos)
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // 1. Dominio
                    TextFormField(
                      controller: _domainController,
                      decoration: const InputDecoration(
                        labelText: 'Dominio Odoo',
                        hintText: 'midominio.com',
                        prefixIcon: Icon(Icons.language),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el dominio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Base de datos (MANUAL - sin búsqueda)
                    TextFormField(
                      controller: _dbNameController,
                      decoration: const InputDecoration(
                        labelText: 'Base de datos',
                        hintText: 'pointsales-v18',
                        prefixIcon: Icon(Icons.storage),
                        border: OutlineInputBorder(),
                        // 🎯 Opcional: Botón de información
                        suffixIcon: Tooltip(
                          message: 'Nombre de la base de datos en Odoo.\nEj: pointsales-v18, mi_empresa_prod, etc.',
                          child: Icon(Icons.info_outline, size: 20),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el nombre de la base de datos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Usuario
                    TextFormField(
                      controller: _userController,
                      decoration: const InputDecoration(
                        labelText: 'Usuario Odoo',
                        hintText: 'admin@tailorw.com',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa el usuario';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 4. Contraseña
                    TextFormField(
                      controller: _passController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Contraseña',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Ingresa la contraseña';
                        }
                        return null;
                      },
                    ),

                    // Mensajes de estado/error
                    if (_statusMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(color: Colors.green),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Botones
              Column(
                children: [
                  // Botón principal
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _saveConfiguration,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Conectar y Guardar',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // 🎯 NUEVO: Botón para probar sin guardar
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _testConnection,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Probar Conexión',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Texto informativo
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      '📝 El nombre de la base de datos es específico de tu instalación de Odoo.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Ejemplos comunes: pointsales-v18, production_db, company_name',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎯 MÉTODO PARA PROBAR CONEXIÓN (sin guardar)
  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _statusMessage = 'Probando conexión...';
    });

    try {
      final domain = _domainController.text.trim();
      final dbName = _dbNameController.text.trim();
      final username = _userController.text.trim();
      final password = _passController.text.trim();

      print('🔍 Probando conexión...');
      print('   🌐 Dominio: $domain');
      print('   💾 BD: $dbName');
      print('   👤 Usuario: $username');

      final odooService = OdooServiceEnhanced(
        baseUrl: 'https://$domain',
        dbName: dbName,
      );

      final success = await odooService.login(username, password);
      
      if (success && odooService.uid != null) {
        final companyName = odooService.getCompanyName() ?? 'Mi Empresa';
        setState(() {
          _statusMessage = '✅ ¡Conexión exitosa!\n'
                          '🏢 Empresa: $companyName\n'
                          '👤 Usuario: $username\n'
                          '💾 Base de datos: $dbName';
          _errorMessage = '';
        });
        
        // 🎯 AUTO-GUARDAR después de prueba exitosa (opcional)
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && _statusMessage.contains('✅')) {
            _saveConfiguration();
          }
        });
        
      } else {
        setState(() {
          _errorMessage = '❌ Conexión fallida. Verifica:\n'
                         '• Dominio correcto\n'
                         '• Nombre de base de datos\n'
                         '• Usuario/contraseña';
          _statusMessage = '';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error de conexión: $e');
      setState(() {
        _errorMessage = 'Error de conexión:\n$e';
        _statusMessage = '';
        _isLoading = false;
      });
    }
  }

  // 🎯 MÉTODO PARA GUARDAR CONFIGURACIÓN
  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _statusMessage = 'Guardando configuración...';
    });

    try {
      final domain = _domainController.text.trim();
      final dbName = _dbNameController.text.trim();
      final username = _userController.text.trim();
      final password = _passController.text.trim();

      print('💾 Guardando configuración...');
      print('   🌐 Dominio: $domain');
      print('   💾 BD: $dbName');
      print('   👤 Usuario: $username');

      // 1. Crear servicio y conectar
      final odooService = OdooServiceEnhanced(
        baseUrl: 'https://$domain',
        dbName: dbName,
      );

      final success = await odooService.login(username, password);
      
      if (!success || odooService.uid == null) {
        setState(() {
          _errorMessage = 'Credenciales incorrectas. Verifica los datos.';
          _statusMessage = '';
          _isLoading = false;
        });
        return;
      }

      // 2. Obtener información de la empresa
      final companyName = odooService.getCompanyName() ?? 'Mi Empresa';
      
      // 3. Crear configuración
      final config = OdooConfig(
        domain: domain,
        dbName: dbName,
        companyName: companyName,
        username: username,
        password: password,
        odooVersion: '19.0',
      );

      // 4. Guardar configuración
      await ConfigManager.saveConfig(config);
      
      // 5. Verificar que se guardó
      final savedConfig = await ConfigManager.getActiveConfig();
      if (savedConfig == null) {
        throw Exception('No se pudo guardar la configuración');
      }

      // 6. Log exitoso
      print('✅ Configuración guardada exitosamente');
      print('   🏢 Empresa: $companyName');
      print('   👤 Usuario: $username');
      print('   🌐 Dominio: $domain');
      print('   💾 Base de datos: $dbName');
      
      // 7. Navegar al home
      Navigator.pushReplacementNamed(context, '/');

    } catch (e) {
      print('❌ Error guardando configuración: $e');
      setState(() {
        _errorMessage = 'Error: $e';
        _statusMessage = '';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _domainController.dispose();
    _dbNameController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }
}
