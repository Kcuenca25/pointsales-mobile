import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/screens/forms/form_change_password.dart';

void main() => runApp(const SettingsPage());

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Card(
                color: Colors.white,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: const Border(
                  bottom: BorderSide(color: Color.fromARGB(255, 226, 216, 216)), 
                ),
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20.0), 
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton( 
                            icon: const Icon(Icons.arrow_back, color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: const ButtonStyle(backgroundColor: WidgetStatePropertyAll(Colors.blueAccent),),
                            padding: EdgeInsets.zero,
                            iconSize: 20.0,
                            alignment: Alignment.center
                          ),
                          const SizedBox(width: 8),
                          const Expanded(child: Center(child: Text('Configuraciones', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold)))),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const FormChangePassword()),
                  );
                },
                child: const Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: Border(
                    bottom: BorderSide(color: Colors.white), 
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20.0), 
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline, color: Colors.grey),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cambiar contraseña',
                              style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Actualice su contraseña regularmente',
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
              const Card(
                color: Colors.white,
                elevation: 0,
                margin: EdgeInsets.zero,
                shape: Border(
                  bottom: BorderSide(color: Colors.white), // Borde inferior de color gris
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: 20.0), // Añadir espaciado inferior
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.notifications_active_outlined, color: Colors.grey),
                      SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Ajustar notificaciones',
                            style: TextStyle(color: Colors.black,fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Configure las notificaciones que desea recibir',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
                  _showLogoutDialog(context);
                },
                child: const Card(
                  color: Colors.white,
                  elevation: 0,
                  margin: EdgeInsets.zero,
                  shape: Border(
                    bottom: BorderSide(color: Colors.white), 
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20.0), 
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.warning_amber_outlined, color: Colors.redAccent),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Eliminar cuenta',
                              style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Acción permanente que le impedirá utilizar la aplicación',
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
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("¿Desea eliminar su cuenta?"),
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
