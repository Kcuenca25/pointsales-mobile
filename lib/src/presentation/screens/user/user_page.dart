import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/components/custon_bar_row/custon_bar_row.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_button.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/03-car_shop_screen.dart';
import 'package:flutter/material.dart';

class UserPage extends StatelessWidget {
  final User usuario;
  final Function(User) onProductListNavigate; 

  const UserPage({super.key, required this.usuario, required this.onProductListNavigate});

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
              CustomBarRow(
                title: 'Ordenes de compra',
                onBackButtonPressed: () {
                  Navigator.pop(context);
                },
                backgroundColor: Colors.blueAccent,
                textColor: Colors.black,
              ),
              const SizedBox(height: 8),
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  '${usuario.name?.firstname?.substring(0, 1) ?? ''}${usuario.name?.lastname?.substring(0, 1) ?? ''}', // Iniciales
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 20),
              Text('${usuario.name?.firstname} ${usuario.name?.lastname}', style: const TextStyle(fontSize: 24)),
              Text('${usuario.username ?? ''}', style: const TextStyle(color: Colors.grey)),
              Text('${usuario.phone ?? ''}', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),
              CustomElevatedButton(
                text: 'Nueva orden de compra',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CarShopScreen(
                        selectedIndex: 2,
                        onProductListNavigate: onProductListNavigate, 
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: 1, 
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/users');
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/car_shop_screen');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/purchase_history');
              break;
            case 4:
              Navigator.pushReplacementNamed(context, '/profile_screen');
              break;
          }
        },
      ),
    );
  }
}
