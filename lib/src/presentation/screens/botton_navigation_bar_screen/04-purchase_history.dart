import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/components/custon_bar_row/custon_bar_row.dart';
import 'package:ecomerce_app/src/presentation/screens/product/product_new_order_buy.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';

class PurchaseHistory extends StatelessWidget {
  final List<Map<String, dynamic>> purchaseHistory;

  const PurchaseHistory({Key? key, required this.purchaseHistory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CustonAppBar(),
            const SizedBox(height: 20),
            CustomBarRow(
              title: 'Historial de compras',
              onBackButtonPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductNewOrderBuy()));
              },
              backgroundColor: Colors.blueAccent,
              textColor: Colors.black,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: purchaseHistory.isEmpty
                  ? const Center(child: Text('No hay historial de compras.'))
                  : ListView.builder(
                      itemCount: purchaseHistory.length,
                      itemBuilder: (context, index) {
                        final purchase = purchaseHistory[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: NetworkImage(purchase['products'][0]['image'] ?? 'https://via.placeholder.com/150'),
                                ),
                                title: Text('Usuario: ${purchase['user']}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Producto: ${purchase['products'][0]['title']}'),
                                    Text('Descripción: ${purchase['products'][0]['description']}'),
                                    Text('Cantidad: ${purchase['products'][0]['quantity']}'),
                                    Text('Precio Unitario: \$${purchase['products'][0]['price'].toStringAsFixed(2)}'),
                                    Text('Precio Total: \$${purchase['totalPrice'].toStringAsFixed(2)}'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: 3,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home_screen');
              break;
            case 1:
              Navigator.pushReplacementNamed(context, '/client_screen');
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
