import 'package:ecomerce_app/src/presentation/components/custon_bar_row/custon_bar_row.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/data/api_repository/api_repository.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
import 'package:ecomerce_app/src/presentation/components/custon_search/custon_search_product.dart';
import 'package:ecomerce_app/src/presentation/components/product_item.dart';
import 'package:ecomerce_app/src/presentation/screens/product/product_order_summary.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart'; // Importar el CustomCircleNavBar

class ProductList extends StatefulWidget {
  final User selectedUser;

  const ProductList({Key? key, required this.selectedUser}) : super(key: key);

  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  late Future<List<Product>> futureProducts;
  List<Product> allProducts = [];
  List<Product> filteredProducts = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureProducts = ApiServices().fetchAllProducts();
    futureProducts.then((products) {
      setState(() {
        allProducts = products;
        filteredProducts = products;
      });
    });
  }

  void filterProducts(String query) {
    final products = allProducts.where((product) {
      final title = product.title!.toLowerCase();
      return title.contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredProducts = products;
    });
  }

  void toggleSelection(Product product) {
    setState(() {
      product.isSelected = !product.isSelected;
    });
  }

  void onQuantityChange(Product product, int quantity) {
    setState(() {
      product.quantity = quantity;
    });
  }

  double get totalPrice {
    return filteredProducts.fold(0, (sum, product) {
      return sum + (product.isSelected ? product.price! * product.quantity : 0);
    });
  }

  bool get isAnySelected {
    return filteredProducts.any((product) => product.isSelected);
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
                title: 'Lista de productos',
                onBackButtonPressed: () {
                  Navigator.pop(context);
                },
                backgroundColor: Colors.blueAccent, textColor: Colors.black,
              ),
            const SizedBox(height: 20),
            CustonSearchProduct(
              controller: searchController,
              onTextChanged: filterProducts,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<Product>>(
                future: futureProducts,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else {
                    return ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        return ProductItem(
                          product: filteredProducts[index],
                          onQuantityChange: onQuantityChange,
                          onLongPress: toggleSelection,
                          isSelected: filteredProducts[index].isSelected,
                        );
                      },
                    );
                  }
                },
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Total: \$${totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            Center(
              child: ElevatedButton(
                onPressed: isAnySelected ? () {
                  List<Product> selectedProducts = filteredProducts.where((product) => product.isSelected).toList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrderSummary(selectedProducts: selectedProducts, selectedUser: widget.selectedUser),
                    ),
                  );
                } : null, // Inactivo cuando isAnySelected es false
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: isAnySelected ? Colors.blueAccent : Colors.grey, // Color de las letras
                  minimumSize: const Size(double.infinity, 60), // Tamaño del botón (largo de izquierda a derecha)
            ),
              child: const Text(
                'Confirmar pedido',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          )

          ],
        ),
      ),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: 2, // Cambia según la posición de esta pantalla
        onItemTapped: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/users');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/products');
          }
        },
      ),
    );
  }
}
