import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/presentation/components/botton_navigation_bar/circle_navbar.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/01-home_screen_content.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/02-client_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/03-car_shop_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/04-purchase_history.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/05-profile_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/product/product_list.dart';
import 'package:ecomerce_app/src/presentation/screens/user/user_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late PageController pageController;
  final List<Map<String, dynamic>> purchaseHistory = []; // Lista para el historial de compras

  @override
  void initState() {
    super.initState();
    pageController = PageController(initialPage: _selectedIndex);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    pageController.jumpToPage(index);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          HomeScreenContent(onUserPageNavigate: (User user) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserPage(
                usuario: user,
                onProductListNavigate: (User selectedUser) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProductList(selectedUser: selectedUser)),
                  );
                },
              )),
            );
          }),
          ClientScreen(onUserPageNavigate: (User user) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => UserPage(
                usuario: user,
                onProductListNavigate: (User selectedUser) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProductList(selectedUser: selectedUser)),
                  );
                },
              )),
            );
          }),
          CarShopScreen(onProductListNavigate: (User user) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProductList(selectedUser: user)),
            );
          }),
          PurchaseHistory(purchaseHistory: purchaseHistory), // Pasar el historial de compras
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: CustomCircleNavBar(
        selectedIndex: _selectedIndex,
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
              Navigator.pushReplacementNamed(context, '/purchase_history', arguments: purchaseHistory); // Pasar el historial de compras
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
