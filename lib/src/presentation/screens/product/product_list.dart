import 'package:ecomerce_app/src/presentation/components/custon_bar_row/custon_bar_row.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/data/api_repository/databaseHelper.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/presentation/components/custon_search/custon_search_product.dart';
import 'package:ecomerce_app/src/presentation/components/product_item.dart';
import 'package:ecomerce_app/src/presentation/screens/product/product_order_summary.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart'; // Importar el CustomCircleNavBar

class ProductList extends StatefulWidget {
  final User? selectedUser; // ✅ Para carrito de compras del usuario del sistema
  final Customer? selectedCustomer; // ✅ Para órdenes de venta de clientes Odoo

  const ProductList({
    Key? key,
    this.selectedUser,
    this.selectedCustomer,
  }) : super(key: key);

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
    futureProducts = _loadProductsFromOdoo(); // ✅ SOLO USAR ESTE MÉTODO
  }

  // ✅ IMPLEMENTAR EL MÉTODO _loadProductsFromOdoo QUE FALTA
  Future<List<Product>> _loadProductsFromOdoo() async {
    try {
      final odooService = OdooServiceEnhanced(
        baseUrl: 'https://pointsalesqa.tailorw.net/jsonrpc',
        dbName: 'pointsales_prodv18',
      );
      
      bool isAuthenticated = await odooService.login('admin', 'admin');
      
      if (isAuthenticated) {
        final productService = OdooProductService(odooService);
        final products = await productService.getProducts(limit: 50);
        
        // ✅ ACTUALIZAR EL ESTADO CUANDO LOS PRODUCTOS SE CARGUEN
        if (mounted) {
          setState(() {
            allProducts = products;
            filteredProducts = products;
          });
        }
        
        return products;
      } else {
        throw Exception('Error de autenticación con Odoo');
      }
    } catch (e) {
      print('❌ Error cargando productos de Odoo: $e');
      
      // ✅ FALLBACK: Cargar de base de datos local si Odoo falla
      try {
        final dbHelper = DatabaseHelper();
        final localProducts = await dbHelper.getProducts();
        
        if (mounted) {
          setState(() {
            allProducts = localProducts;
            filteredProducts = localProducts;
          });
        }
        
        return localProducts;
      } catch (localError) {
        print('❌ Error cargando productos locales: $localError');
        return []; // Devolver lista vacía en caso de error
      }
    }
  }

  void filterProducts(String query) {
    final products = allProducts.where((product) {
      final title = product.title.toLowerCase();
      final name = product.name.toLowerCase();
      final defaultCode = product.defaultCode?.toLowerCase() ?? '';
      
      return title.contains(query.toLowerCase()) ||
             name.contains(query.toLowerCase()) ||
             defaultCode.contains(query.toLowerCase());
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
      return sum + (product.isSelected ? product.price * product.quantity : 0);
    });
  }

  bool get isAnySelected {
    return filteredProducts.any((product) => product.isSelected);
  }

  // ✅ MÉTODO PARA REFRESCAR PRODUCTOS
  void _refreshProducts() {
    setState(() {
      futureProducts = _loadProductsFromOdoo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            
            // ✅ CABECERA CON BOTÓN DE ACTUALIZAR
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomBarRow(
                  title: 'Lista de productos',
                  onBackButtonPressed: () {
                    Navigator.pop(context);
                  },
                  backgroundColor: Colors.blueAccent,
                  textColor: Colors.black,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _refreshProducts,
                  tooltip: 'Actualizar productos',
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            CustonSearchProduct(
              controller: searchController,
              onTextChanged: filterProducts,
            ),
            const SizedBox(height: 20),
            
            // ✅ INDICADOR DE CARGA
            FutureBuilder<List<Product>>(
              future: futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  return Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _refreshProducts,
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Expanded(
                    child: Center(
                      child: Text('No hay productos disponibles'),
                    ),
                  );
                } else {
                  // ✅ LISTA DE PRODUCTOS
                  return Expanded(
                    child: ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];

                        return Dismissible(
                          key: Key(product.id.toString()),
                          direction: DismissDirection.startToEnd,
                          background: Container(
                            color: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.centerLeft,
                            child: const Row(
                              children: [
                                Icon(Icons.delete, color: Colors.white),
                                SizedBox(width: 10),
                                Text("Eliminar", style: TextStyle(color: Colors.white, fontSize: 16)),
                              ],
                            ),
                          ),
                          onDismissed: (direction) {
                            setState(() {
                              allProducts.remove(product);
                              filteredProducts.removeAt(index);
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.title} eliminado')),
                            );
                          },
                          child: ProductItem(
                            product: product,
                            onQuantityChange: onQuantityChange,
                            onLongPress: toggleSelection,
                            isSelected: product.isSelected,
                          ),
                        );
                      },
                    ),
                  );
                }
              },
            ),
            
            // ✅ TOTAL Y BOTÓN DE CONFIRMAR
            Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Total: \$${totalPrice.toStringAsFixed(2)}', 
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            
            Center(
              child: ElevatedButton(
                onPressed: isAnySelected ? () {
                  List<Product> selectedProducts = filteredProducts.where((product) => product.isSelected).toList();
                  
                  // ✅ VERIFICAR SI ES PARA USUARIO O CLIENTE ODDO
                  if (widget.selectedUser != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderSummary(
                          selectedProducts: selectedProducts,
                          selectedUser: widget.selectedUser!,
                          selectedCustomer: widget.selectedCustomer,
                        ),
                      ),
                    );
                  } else if (widget.selectedCustomer != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OrderSummary(
                          selectedProducts: selectedProducts,
                          selectedUser: null,
                          selectedCustomer: widget.selectedCustomer,
                        ),
                      ),
                    );
                  } else {
                    // Manejar caso donde no hay ni usuario ni cliente
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: No se ha seleccionado un cliente')),
                    );
                  }
                } : null,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, 
                  backgroundColor: isAnySelected ? Colors.blueAccent : Colors.grey,
                  minimumSize: const Size(double.infinity, 60),
                ),
                child: const Text(
                  'Confirmar pedido',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: 2,
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