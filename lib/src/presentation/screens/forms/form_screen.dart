import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_button.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_text.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_text_form_field.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';

class FormScreen extends StatefulWidget {
  const FormScreen({super.key});

  @override
  State<FormScreen> createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final _login = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool passToggle = false;
  bool showErrors = false; // Variable para controlar la visibilidad de errores

  String? validateEmail(String? value) {
    if (!showErrors) return null;
    if (value == null || value.isEmpty) {
      return 'El campo correo electrónico no puede estar vacío';
    }
    final emailRegExp = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegExp.hasMatch(value)) {
      return 'Por favor, ingrese un correo electrónico válido';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (!showErrors) return null;
    if (value == null || value.isEmpty) {
      return 'EL campo contraseña no puede estar vacío';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  void _submitForm() {
    setState(() {
      showErrors = true; // Mostrar errores al presionar el botón
    });

    if (_login.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.blue, // Fondo azul para toda la pantalla
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(25.0),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 90,
                color: Colors.white, // Color blanco para el icono
              ),
            ),
            const SizedBox(height: 1),
            const CustomText(
              text: 'Ventas +',
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
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const CustomText(
                          text: 'Iniciar sesión',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, 
                        ),
                        const SizedBox(height: 16),
                        CustomTextFormField(
                          controller: emailController,
                          labelText: 'Correo electrónico',
                          hintText: 'admin@email.com',
                          prefixIcon: Icons.email_outlined,
                          validator: validateEmail,
                        ),
                        const SizedBox(height: 16),
                        CustomTextFormField(
                          controller: passwordController,
                          labelText: 'Contraseña',
                          hintText: '***',
                          prefixIcon: Icons.lock_outline,
                          obscureText: passToggle,
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
                            onPressed: () {},
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
                        CustomElevatedButton(
                          text: 'Acceder',
                          onPressed: _submitForm,
                        ),
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
}