import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart'; // Importar el CustomCircleNavBar

void main() => runApp(const ProfileScreen());

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              const CustonAppBar(),
              const SizedBox(height: 20),
              const Card(
                color: Colors.white,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: Border(
                  bottom: BorderSide(color: Color.fromARGB(255, 226, 216, 216)), // Borde inferior de color gris
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20.0), // Añadir espaciado inferior
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Mi perfil',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      CircleAvatar(
                        radius: 40,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Nombre .....',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(Icons.email_outlined, color: Colors.grey,),
                          SizedBox(width: 10),
                          Text(
                            'alexsl@gmail.com',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(right: 25), // Correr hacia la izquierda
                            child: Icon(Icons.phone_outlined, color: Colors.grey,),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 35),
                            child: Text(
                              '123457890',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  // Agrega aquí la funcionalidad para configuraciones
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()));
                    print("Configuraciones tap");
                },
                child: const Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: Border(
                    bottom: BorderSide(color: Color.fromARGB(255, 226, 216, 216)), // Borde inferior de color gris
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20.0), // Añadir espaciado inferior
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.settings, color: Colors.blueAccent),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Configuraciones',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Mantenga la configuración de su cuenta actualizada',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  _showLogoutDialog(context);
                },
                child: const Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: Border(
                    bottom: BorderSide(color: Color.fromARGB(255, 226, 216, 216)), // Borde inferior de color gris
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20.0), // Añadir espaciado inferior
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.logout_outlined, color: Colors.blueAccent),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cerrar sesión',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Terminar de utilizar la aplicación por hoy',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: 4, // Cambia según la posición de esta pantalla
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("¿Desea cerrar su sesión?"),
          actions: [
            TextButton(
              child: const Text("No"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text("Sí"),
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }
}
