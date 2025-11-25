import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/01-home_screen_content.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/02-client_screen.dart';
//import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/03-car_shop_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/04-purchase_history.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/05-profile_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/product/product_list.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_de_page.dart';
//import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/06-maps.dart';
  //import 'package:ecomerce_app/src/presentation/screens/user/new_orden_page.dart'; // importa el estado global
  //import 'package:badges/badges.dart' as badges;
  ////import 'package:ecomerce_app/src/presentation/screens/user/orden_incompleta.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/appDrawer.dart';
import 'package:ecomerce_app/src/presentation/components/custon_appbar/custon_appbar.dart';
//import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart'; // importa el estado global
import 'package:ecomerce_app/src/providers/helper/usuario_providers.dart'; 
//import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';

//import 'package:ecomerce_app/src/domain/models/articulo.dart'; 
//import 'package:ecomerce_app/src/services/connectivity_service.dart';
//import 'package:ecomerce_app/src/data/api_repository/inventario/inventory_service_odoo.dart';
import 'package:ecomerce_app/src/data/api_repository/inventario/inventory_sync_manager.dart';
import 'package:provider/provider.dart'; 

class HomeScreen extends StatefulWidget {
  final int? initialIndex;

  const HomeScreen({super.key, this.initialIndex});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late PageController pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex ?? 0;
    pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _getScreenForIndex(index),
        ),
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {});
  }


  @override
  Widget build(BuildContext context) {

    return Consumer<UsuarioProvider>(
      builder: (context, usuarioProvider, child) {
        return Scaffold(
          appBar: CustomAppBar(
            title: _getTitleForIndex(_selectedIndex),
            onOrdenTerminada: () {
              setState(() {});
            },
            showTitle: false,
            // ✅ PASAR LOS DATOS DEL PROVIDER AL CUSTOM APP BAR
            //companyName: usuarioProvider.companyName,
            //userName: usuarioProvider.userName,
          ),
          drawer: AppDrawer(
            onItemTapped: (index) {
              _onItemTapped(index);
            },
          ),
          body: PageView(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              HomeScreenContent(
                onUserPageNavigate: (customer) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrdenPago(
                        customer: customer,
                        onProductListNavigate: (selectedCustomer) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductList(
                                selectedCustomer: selectedCustomer,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              ClientScreen(
                onCustomerPageNavigate: (customer) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OrdenPago(
                        customer: customer,
                        onProductListNavigate: (selectedCustomer) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductList(
                                selectedCustomer: selectedCustomer,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
              PurchaseHistory(purchaseHistory: []),
              const ProfileScreen(),
              PlaceSearchScreen(),
            ],
          ),
          bottomNavigationBar: CustomCircleNavBar(
            selectedIndex: _selectedIndex,
            onItemTapped: _onItemTapped,
          ),
        );
      },
    );
  }

  // Método auxiliar para obtener la pantalla correspondiente al índice
  Widget _getScreenForIndex(int index) {
    switch (index) {
      case 0:
        return HomeScreenContent(
          onUserPageNavigate: (user) {
            // Manejar la navegación
          },
        );
      case 1:
        return ClientScreen(
          onCustomerPageNavigate: (user) {
            // Manejar la navegación
          },
        );
      case 3:
        return PurchaseHistory(purchaseHistory: []);
      case 4:
        return const ProfileScreen();
      case 5:
        return PlaceSearchScreen();
      default:
        return HomeScreenContent(
          onUserPageNavigate: (user) {
            // Manejar la navegación
          },
        );
    }
  }

  String _getTitleForIndex(int index) {
    switch (index) {
      case 0:
        return "Inicio";
      case 1:
        return "Clientes";
      case 2:
        return "Carrito";
      case 3:
        return "Historial";
      case 4:
        return "Perfil";
      case 5:
        return "Mapa";
      default:
        return "App Movistar";
    }
  }


//botón de Sincronización Manual
//   Widget _buildBotonSincronizacionInventario() {
//   return Consumer<InventorySyncManager>(
//     builder: (context, syncManager, child) {
//       return FloatingActionButton.extended(
//         onPressed: () async {
//           final result = await syncManager.performQuickSync();
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(result ? '✅ Inventario sincronizado' : '❌ Error sincronizando'),
//               backgroundColor: result ? Colors.green : Colors.red,
//             ),
//           );
//         },
//         icon: const Icon(Icons.sync),
//         label: const Text('Sincronizar Inventario'),
//         backgroundColor: Colors.deepPurple,
//       );
//     },
//   );
// }
}