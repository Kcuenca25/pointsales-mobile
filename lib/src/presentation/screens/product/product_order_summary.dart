import 'package:ecomerce_app/src/presentation/components/custon_bar_row/custon_bar_row.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_form/custon_button.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart'; // Importar el CustomCircleNavBar

class OrderSummary extends StatelessWidget {
  final List<Product> selectedProducts;
  final User selectedUser;

  const OrderSummary({Key? key, required this.selectedProducts, required this.selectedUser}) : super(key: key);

  double get totalPrice {
    return selectedProducts.fold(0, (sum, product) {
      return sum + (product.price! * product.quantity);
    });
  }

  void _handleConfirm(BuildContext context) {
    // Guardar la orden en el historial de compras
    final purchase = {
      'user': selectedUser.name?.firstname ?? '',
      'products': selectedProducts.map((product) => {
        'title': product.title,
        'image': product.image,
        'description': product.description,
        'quantity': product.quantity,
        'price': product.price,
      }).toList(),
      'totalPrice': totalPrice,
    };

    // Navega a la pantalla SuccessfullScreen
    Navigator.pushNamed(
      context,
      '/success_screen',
      arguments: [purchase],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustonAppBar(),
            const SizedBox(height: 20),
            CustomBarRow( 
                title: 'Orden de compra',
                onBackButtonPressed: () {
                  Navigator.pop(context);
                },
                backgroundColor: Colors.blueAccent, textColor: Colors.black,
              ),
            Expanded(
              child: ListView.builder(
                itemCount: selectedProducts.length,
                itemBuilder: (context, index) {
                  final product = selectedProducts[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Image.network(
                            product.image ?? 'https://via.placeholder.com/150',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(product.title ?? 'Producto sin nombre'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cantidad: ${product.quantity}'),
                              const SizedBox(height: 10),
                              Text(
                                '${product.description ?? 'Sin descripción'}',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '\$${(product.price! * product.quantity).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, color: Colors.green),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Center(
                child: Text(
                  'Total: \$${totalPrice.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Center(
              child: CustomElevatedButton(
                        text: 'Confirmar pedido',
                        onPressed: () {
                          _handleConfirm(context);
                        },
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
          }
          // Agrega más navegación según tus pantallas
        },
      ),
    );
  }
}
  