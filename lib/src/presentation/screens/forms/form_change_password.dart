import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_button.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_text.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_text_form_field.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';

class FormChangePassword extends StatefulWidget {
  const FormChangePassword({super.key});

  @override
  State<FormChangePassword> createState() => _FormChangePasswordState();
}

class _FormChangePasswordState extends State<FormChangePassword> {
  final _changePassword = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool passToggle = true;
  bool showErrors = false; // Variable para controlar la visibilidad de errores

  String? validateEmail(String? value) {
    if (!showErrors) return null;
    if (value == null || value.isEmpty) {
      return 'El correo electrónico no puede estar vacío';
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
      return 'La contraseña no puede estar vacía';
    }
    if (value.length < 8) {
      return 'La contraseña debe tener al menos 8 caracteres';
    }
    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (!showErrors) return null;
    if (value == null || value.isEmpty) {
      return 'La confirmación de la contraseña no puede estar vacía';
    }
    if (value != newPasswordController.text) {
      return 'Las contraseñas no coinciden';
    }
    return null;
  }

  void _submitForm() {
    setState(() {
      showErrors = true; // Mostrar errores al presionar el botón
    });

    if (_changePassword.currentState!.validate()) {
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
              color: Colors.white, // Color blanco para el texto
            ),
            const SizedBox(height: 29),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(40.0), // Añadimos padding interno
                decoration: const BoxDecoration(
                  color: Colors.white, // Fondo blanco para el container
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ), // Borde redondeado en la parte superior
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _changePassword,
                    autovalidateMode: AutovalidateMode.disabled, // Deshabilitar la validación automática
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const CustomText(
                          text: 'Cambiar contraseña',
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Color negro para el texto
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
                          controller: oldPasswordController,
                          labelText: 'Contraseña vieja',
                          hintText: '***',
                          prefixIcon: Icons.lock_outline,
                          obscureText: passToggle,
                          validator: validatePassword,
                        ),
                        const SizedBox(height: 16),
                        CustomTextFormField(
                          controller: newPasswordController,
                          labelText: 'Contraseña nueva',
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
                        CustomTextFormField(
                          controller: confirmPasswordController,
                          labelText: 'Repetir contraseña nueva',
                          hintText: '***',
                          prefixIcon: Icons.lock_outline,
                          obscureText: passToggle,
                          validator: validateConfirmPassword,
                        ),
                        const SizedBox(height: 40),
                        CustomElevatedButton(
                          text: 'Cambiar',
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
