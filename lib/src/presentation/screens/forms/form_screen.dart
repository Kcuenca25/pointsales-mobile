import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart'; 
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_button.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_text.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_text_form_field.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/forms/forgot_password_screen.dart'; 
import 'package:ecomerce_app/src/config/api_config.dart';

import 'package:provider/provider.dart'; 
import 'package:ecomerce_app/src/providers/helper/usuario_providers.dart';

//import 'package:flutter/material.dart';
//import 'package:local_auth/local_auth.dart'; 
//import 'package:ecomerce_app/src/presentation/components/custon_form/custon_button.dart';
//import 'package:ecomerce_app/src/presentation/components/custon_form/custon_text.dart';
//import 'package:ecomerce_app/src/presentation/components/custon_form/custon_text_form_field.dart';
//import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
//import 'package:ecomerce_app/src/presentation/screens/forms/forgot_password_screen.dart'; 
//import 'package:provider/provider.dart'; 
//import 'package:ecomerce_app/src/providers/helper/usuario_providers.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_auth_service.dart'; 

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _login = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool passToggle = false;
  bool showErrors = false;
  bool _isLoading = false;
  bool _biometricAvailable = false;
  String _errorMessage = '';

  final LocalAuthentication auth = LocalAuthentication();
  final OdooAuthService _odooAuthService = OdooAuthService();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _loadDefaultCredentials();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();

      setState(() {
        _biometricAvailable = canCheckBiometrics && isDeviceSupported;
      });

      if (_biometricAvailable) {
        _authenticateWithBiometric();
      }
    } catch (e) {
      print('Error verificando biometría: $e');
      setState(() {
        _biometricAvailable = false;
      });
    }
  }

  Future<void> _authenticateWithBiometric() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final bool authenticated = await auth.authenticate(
        localizedReason: 'Usa tu huella digital para acceder a PointSales',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );

      if (authenticated) {
        print('✅ Autenticación biométrica exitosa');
        await _authenticateWithOdoo('admin', 'admin');
      } else {
        setState(() {
          _errorMessage = 'Autenticación biométrica fallida o cancelada';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error en autenticación biométrica: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _enterAppWithUser(String username, int userId, String sessionId) async {
    final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
    await usuarioProvider.saveEmail('$username@tailorw.com');
    await usuarioProvider.saveUser(username);
    await usuarioProvider.saveAccessToken(sessionId);
    usuarioProvider.isAuthenticated = true;

    print('🚀 Usuario autenticado: $username (ID: $userId)');
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  void _loadDefaultCredentials() {
    usernameController.text = 'admin';
    passwordController.text = 'admin';
  }

  Future<void> _authenticateWithOdoo(String username, String password) async {
  setState(() {
    _isLoading = true;
    _errorMessage = '';
  });

  try {
    final validation = _odooAuthService.validateCredentials(username, password);
    
    if (!validation['valid']) {
      setState(() {
        _errorMessage = validation['error']!;
        _isLoading = false;
      });
      return;
    }

    final authResult = await _odooAuthService.authenticate(
      username: username,
      password: password,
    );

    if (authResult['success'] == true) {
      final int userId = authResult['userId'];
      final String sessionId = authResult['sessionId'];
      final String companyName = authResult['companyName'] ?? 'Mi Empresa';
      final String userName = authResult['userName'] ?? username;
      
      print('✅ Login Odoo exitoso!');
      print('   👤 User ID: $userId');
      print('   🏢 Empresa: $companyName');
      print('   👤 Nombre: $userName');
      
      // ✅ ACTUALIZAR EL PROVIDER CON LA INFORMACIÓN DE LA EMPRESA
      final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
      await usuarioProvider.saveEmail('$username@tailorw.com');
      await usuarioProvider.saveUser(username);
      await usuarioProvider.saveAccessToken(sessionId);
      await usuarioProvider.saveCompanyName(companyName); // ✅ GUARDAR EMPRESA
      await usuarioProvider.saveUserName(userName);       // ✅ GUARDAR NOMBRE USUARIO
      
      usuarioProvider.isAuthenticated = true;
      usuarioProvider.userId = userId;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = authResult['error'] ?? 'Error de autenticación Odoo';
        _isLoading = false;
      });
    }
  } catch (e) {
    setState(() {
      _errorMessage = 'Error de conexión: $e';
      _isLoading = false;
    });
  }
}

  // ✅ MÉTODO ACTUALIZADO: Usar el UsuarioProvider en lugar de OdooAuthService directamente
  Future<void> _authenticateWithUsuarioProvider(String username, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final usuarioProvider = Provider.of<UsuarioProvider>(context, listen: false);
      
      // ✅ USAR EL MÉTODO DEL PROVIDER
      final success = await usuarioProvider.loginWithOdoo(username, password);
      
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      } else {
        setState(() {
          _errorMessage = 'Credenciales incorrectas';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  String? validateUsername(String? value) {
    if (!showErrors) return null;
    if (value == null || value.isEmpty) {
      return 'El campo usuario no puede estar vacío';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (!showErrors) return null;
    if (value == null || value.isEmpty) {
      return 'El campo contraseña no puede estar vacío';
    }
    return null;
  }

  void _submitForm() {
    setState(() {
      showErrors = true;
    });

    if (_login.currentState!.validate()) {
      // ✅ USAR EL MÉTODO QUE PREFIERAS:
      // Opción 1: Directo con OdooAuthService (actual)
      _authenticateWithOdoo(
        usernameController.text.trim(),
        passwordController.text.trim(),
      );
      
      // Opción 2: Con UsuarioProvider (alternativa)
      // _authenticateWithUsuarioProvider(
      //   usernameController.text.trim(),
      //   passwordController.text.trim(),
      // );
    }
  }

  void _navigateToForgotPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ForgotPasswordScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.blue,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(25.0),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 90,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 1),
            const CustomText(
              text: 'VENTAS',
              fontSize: 33,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            const SizedBox(height: 29),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(40.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _login,
                    autovalidateMode: AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const CustomText(
                          text: 'Iniciar sesión ',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        
                        // const SizedBox(height: 10),
                        // const Text(
                        //   'Conectando a Odoo PointSales',
                        //   style: TextStyle(
                        //     color: Colors.grey,
                        //     fontSize: 14,
                        //   ),
                        //   textAlign: TextAlign.center,
                        // ),
                        
                        const SizedBox(height: 16),
                        
                        if (_errorMessage.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error, color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage,
                                    style: const TextStyle(color: Colors.red, fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        CustomTextFormField(
                          controller: usernameController,
                          labelText: 'Usuario',
                          hintText: 'admin',
                          prefixIcon: Icons.person_outline,
                          validator: validateUsername,
                        ),
                        const SizedBox(height: 16),
                        CustomTextFormField(
                          controller: passwordController,
                          labelText: 'Contraseña',
                          hintText: 'admin',
                          prefixIcon: Icons.lock_outline,
                          obscureText: !passToggle,
                          validator: validatePassword,
                          suffixIcon: InkWell(
                            onTap: () {
                              setState(() {
                                passToggle = !passToggle;
                              });
                            },
                            child: Icon(
                              passToggle ? Icons.visibility : Icons.visibility_off,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _navigateToForgotPassword,
                            child: const Text(
                              '¿Olvidó su contraseña?',
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        
                        _isLoading
                            ? const SizedBox(
                                height: 50,
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 10),
                                      Text('Conectando ...'),
                                    ],
                                  ),
                                ),
                              )
                            : CustomElevatedButton(
                                text: 'Iniciar sesión',
                                onPressed: _submitForm,
                              ),
                        
                        const SizedBox(height: 20),
                        
                        if (_biometricAvailable)
                          ElevatedButton.icon(
                            icon: const Icon(Icons.fingerprint),
                            label: const Text('Ingresar con Huella'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _authenticateWithBiometric,
                          ),
                        
                        const SizedBox(height: 20),
                        
                        // Información de conexión Odoo
                        // Card(
                        //   color: Colors.blue[50],
                        //   child: Padding(
                        //     padding: const EdgeInsets.all(12.0),
                        //     child: Column(
                        //       crossAxisAlignment: CrossAxisAlignment.start,
                        //       children: [
                        //         const Row(
                        //           children: [
                        //             Icon(Icons.cloud, color: Colors.blue),
                        //             SizedBox(width: 8),
                        //             Text(
                        //               'Conexión Odoo',
                        //               style: TextStyle(
                        //                 fontWeight: FontWeight.bold,
                        //                 color: Colors.blue,
                        //               ),
                        //             ),
                        //           ],
                        //         ),
                        //         const SizedBox(height: 8),
                        //         Text('Servidor: ${ApiConfig.baseUrl}'),
                        //         Text('Base de datos: ${ApiConfig.dbName}'),
                        //         const SizedBox(height: 4),
                        //         const Text(
                        //           '✅ Credenciales verificadas',
                        //           style: TextStyle(
                        //             fontSize: 12,
                        //             color: Colors.green,
                        //             fontWeight: FontWeight.bold,
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ),
                        //),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}