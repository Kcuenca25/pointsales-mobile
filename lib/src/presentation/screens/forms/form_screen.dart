import 'package:flutter/material.dart';

import 'package:ecomerce_app/src/presentation/components/custon_form/custon_button.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_text.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_text_form_field.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';

class FormScreen extends StatelessWidget {
  const FormScreen({super.key});

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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CustomText(
                        text: 'Iniciar sesión',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Color azul para el texto
                      ),
                      const SizedBox(height: 16),
                      const CustomTextFormField(
                        labelText: 'admin@email.com',
                        hintText: 'Correo electrónico',
                        prefixIcon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 16),
                      const CustomTextFormField(
                        labelText: '***',
                        hintText: 'Contraseña',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // Maneja el enlace de "Olvidó su contraseña"
                          },
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
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HomeScreen(),
                            ),
                          );
                        },
                      ),
                    ],
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
