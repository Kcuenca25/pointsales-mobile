import 'package:ecomerce_app/src/presentation/screens/seccessfull_screen.dart';
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/02-client_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/03-car_shop_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/04-purchase_history.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/05-profile_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/forms/form_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/logo_screens.dart';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Material App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blueAccent,
          unselectedItemColor: Colors.blueAccent,
          showUnselectedLabels: true,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LogoScreens(),
        '/login': (context) => const FormScreen(),
        '/home_screen': (context) => const HomeScreen(),
        '/client_screen': (context) => ClientScreen(),
        '/car_shop_screen': (context) => const CarShopScreen(),
        '/profile_screen': (context) => const ProfileScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/success_screen') {
          final List<Map<String, dynamic>> args = settings.arguments as List<Map<String, dynamic>>;
          return MaterialPageRoute(
            builder: (context) => SuccessfullScreen(purchaseHistory: args),
          );
        }
        if (settings.name == '/purchase_history') {
          final List<Map<String, dynamic>> args = settings.arguments as List<Map<String, dynamic>>;
          return MaterialPageRoute(
            builder: (context) => PurchaseHistory(purchaseHistory: args),
          );
        }
        return null;
      }
    );
  }
}
