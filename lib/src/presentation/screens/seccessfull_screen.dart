import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
import 'package:flutter/material.dart';

class SuccessfullScreen extends StatelessWidget {
  final List<Map<String, dynamic>> purchaseHistory;

  const SuccessfullScreen({super.key, required this.purchaseHistory});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/success.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end, // Alinea el contenido al final
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0), // Espaciado vertical
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/purchase_history',
                    arguments: purchaseHistory,
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue, // Color del botón
                  minimumSize: const Size(double.infinity, 65), // Tamaño del botón (largo de izquierda a derecha y altura ajustada)
                ),
                child: const Text(
                  'Ir a Historial de Compras',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: 2, // Cambia según la posición de esta pantalla
        onItemTapped: (index) {
          // Lógica para navegar a la pantalla correspondiente
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/users');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/products');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/purchase_history'); // Asegúrate de que esta ruta esté definida
          }
          // Agrega más navegación según tus pantallas
        },
      ),
    );
  }
}
