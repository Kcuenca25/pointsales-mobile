// lib/screens/credentials_screen.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';

class CredentialsScreen extends StatefulWidget {
  const CredentialsScreen({super.key});

  @override
  _CredentialsScreenState createState() => _CredentialsScreenState();
}

class _CredentialsScreenState extends State<CredentialsScreen> {
  final _userController = TextEditingController(text: 'admin@tailorw.com');
  final _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  Future<void> _login() async {
    if (_userController.text.isEmpty || _passController.text.isEmpty) {
      setState(() => _errorMessage = 'Por favor completa todos los campos');
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    
    try {
      // Obtener dominio y BD guardados
      final prefs = await SharedPreferences.getInstance();
      final domain = prefs.getString('odoo_domain');
      final database = prefs.getString('odoo_database');
      
      print('🔑 Intentando login...');
      print('   🌐 Dominio: $domain');
      print('   💾 BD: $database');
      print('   👤 Usuario: ${_userController.text}');
      
      if (domain == null || database == null) {
        throw Exception('Configuración incompleta. Vuelve a configurar la app.');
      }
      
      // Conectar a Odoo
      final odooService = OdooServiceEnhanced(
        baseUrl: 'https://$domain',
        dbName: database,
      );
      
      final success = await odooService.login(
        _userController.text,
        _passController.text,
      );
      
      if (success && odooService.uid != null) {
        print('✅ Login exitoso - UID: ${odooService.uid}');
        
        // Guardar UID temporal para esta sesión
        await prefs.setInt('current_uid', odooService.uid!);
        await prefs.setString('current_user', _userController.text);
        await prefs.setString('session_password', _passController.text); // Guardar temporalmente
        
        // Limpiar campos
        _passController.clear();
        
        // Ir a seleccionar empresa
        Navigator.pushReplacementNamed(context, '/select-company');
      } else {
        setState(() {
          _errorMessage = 'Credenciales incorrectas. Verifica usuario y contraseña.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error login: $e');
      setState(() {
        _errorMessage = 'Error de conexión: ${e.toString().replaceAll("Exception: ", "")}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                height: 100,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 20),
              const Text(
                'Iniciar Sesión',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'Ingresa tus credenciales de Odoo',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Formulario
              Column(
                children: [
                  // Campo Usuario
                  TextField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: 'Usuario',
                      hintText: 'admin@tailorw.com',
                      prefixIcon: Icon(Icons.person_outline, color: Colors.deepPurple),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurple),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Campo Contraseña
                  TextField(
                    controller: _passController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.deepPurple),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.deepPurple),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),

                  // Mensaje de error
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 40),

              // Botón de Login
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
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
                          'Iniciar Sesión',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Enlace para configurar de nuevo (si hay problema)
              TextButton(
                onPressed: () async {
                  // Limpiar configuración y volver al inicio
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.remove('odoo_domain');
                  await prefs.remove('odoo_database');
                  await prefs.remove('current_uid');
                  await prefs.remove('current_user');
                  
                  Navigator.pushNamedAndRemoveUntil(
                    context, 
                    '/onboarding-step1', 
                    (route) => false
                  );
                },
                child: const Text(
                  '¿Problemas con la conexión? Configurar de nuevo',
                  style: TextStyle(color: Colors.deepPurple),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }
}
