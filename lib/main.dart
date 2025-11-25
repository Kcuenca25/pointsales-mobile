import 'package:ecomerce_app/src/presentation/screens/seccessfull_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:ecomerce_app/src/presentation/screens/product/product_list.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_de_page.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/02-client_screen.dart';
//import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/03-car_shop_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/04-purchase_history.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/05-profile_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen//06-maps.dart';
import 'package:ecomerce_app/src/presentation/screens/forms/form_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/logo_screens.dart';
import 'package:ecomerce_app/src/presentation/screens/forms/forgot_password_screen.dart';
//import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:ecomerce_app/src/data/api_repository/databaseHelper.dart' as db;
import 'package:ecomerce_app/src/providers/helper/producto_providers.dart';
import 'package:ecomerce_app/src/providers/helper/usuario_providers.dart';
import 'package:ecomerce_app/src/providers/navigator.dart';
//import 'package:ecomerce_app/src/domain/models/model_orden.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
//import 'package:ecomerce_app/src/domain/models/users_model.dart';
//import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
//import 'package:ecomerce_app/src/data/api_repository/databaseHelper.dart';
//import 'package:ecomerce_app/src/data/api_repository/odoo_customer_service.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_auth_service.dart';
import 'package:ecomerce_app/src/config/api_config.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_product_service.dart';

//import 'package:ecomerce_app/src/domain/models/articulo.dart'; 
import 'package:ecomerce_app/src/services/connectivity_service.dart';
import 'package:ecomerce_app/src/data/api_repository/inventario/inventory_service_odoo.dart';
import 'package:ecomerce_app/src/data/api_repository/inventario/inventory_sync_manager.dart';


import 'package:ecomerce_app/src/services/offline_order_service.dart';
import 'package:ecomerce_app/src/services/service_company.dart';
import 'package:ecomerce_app/src/domain/models/proveedores.dart';
import 'package:ecomerce_app/src/data/api_repository/odooProveedorService.dart';
//import 'dart:convert';
//import 'dart:math';
//import 'package:http/http.dart' as http; 
import 'package:hive_flutter/hive_flutter.dart';

// 🎯 CLASE PROVEEDOR CACHE FUERA DE MyApp
class ProveedorCache {
  static List<Proveedor>? proveedores;
  static DateTime? lastPreloadTime;
  
  static Future<void> preloadProveedores() async {
    try {
      final companyService = CompanyService();
      final odooService = companyService.odooService;
      
      if (odooService != null) {
        final proveedorService = OdooProveedorService(odooService);
        proveedores = await proveedorService.getProveedores();
        lastPreloadTime = DateTime.now();
        print('✅ Proveedores pre-cargados: ${proveedores?.length}');
      }
    } catch (e) {
      print('❌ Error pre-cargando proveedores: $e');
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ INICIALIZAR COMPANY SERVICE PRIMERO Y MOSTRAR LOADING MIENTRAS SE CONFIGURA
  runApp(
    FutureBuilder(
      future: _initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.deepPurple,
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      'Inicializando PointSales...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorApp('Error de inicialización: ${snapshot.error}');
        }

        return _buildMainApp();
      },
    ),
  );
}


// ✅ FUNCIÓN PARA INICIALIZAR TODOS LOS SERVICIOS
Future<void> _initializeApp() async {
  print('🚀 Iniciando aplicación PointSales Odoo...');
  
  // 1. Inicializar Hive
  await Hive.initFlutter();
  await Hive.openBox<Map>('offline_orders');
  await Hive.openBox<Map>('cached_customers');
  await Hive.openBox<Map>('cached_products');
  
  // 2. Inicializar base de datos local
  await db.DatabaseHelper().database;
  print('✅ Base de datos local inicializada');
  
  // 3. ✅ INICIALIZAR COMPANY SERVICE - ESTO ES CLAVE
  print('🏢 Inicializando CompanyService...');
  await CompanyService().initialize();
  print('✅ CompanyService inicializado');
    // 🎯 PRE-CARGAR PROVEEDORES EN SEGUNDO PLANO
  print('🚀 Pre-cargando proveedores...');
  ProveedorCache.preloadProveedores().ignore();
  
  // 4. Configurar sincronización automática
  _initAutoSync();
  
  print('🎯 Todos los servicios inicializados correctamente');
}

// ✅ CONSTRUIR LA APP PRINCIPAL
Widget _buildMainApp() {
  return MultiProvider(
    providers: [
      Provider<NavigationService>(create: (_) => NavigationService()),
      ChangeNotifierProvider<UsuarioProvider>(
        create: (_) => UsuarioProvider(),
        lazy: false,
      ),
      ChangeNotifierProvider<ProductProvider>(
        create: (context) => ProductProvider(context.read<NavigationService>()),
      ),
      
      // ✅ SERVICIOS ODDO
      Provider<OdooAuthService>(create: (_) => OdooAuthService()),
      Provider<OdooServiceEnhanced>(
        create: (_) => OdooServiceEnhanced(
          baseUrl: ApiConfig.baseUrl,
          dbName: ApiConfig.dbName,
        ),
      ),
    ],
    child: const MyApp(),
  );
}

// ✅ INICIALIZAR SINCRONIZACIÓN AUTOMÁTICA
void _initAutoSync() {
  // Verificar sincronización al iniciar la app
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    print('🔄 Verificando sincronización al iniciar...');
    await OfflineOrderService.checkAndSync();
  });
  
  // Escuchar cambios de conexión
  ConnectivityService.onConnectivityChanged.listen((result) async {
    final tieneInternet = await ConnectivityService.hasInternet();
    if (tieneInternet) {
      print('🌐 Conexión recuperada - Sincronizando órdenes pendientes...');
      await OfflineOrderService.syncPendingOrders();
    }
  });
  
  print('✅ Sincronización automática configurada');
}

// ✅ FUNCIONES DE SINCRONIZACIÓN DE INVENTARIO (MANTENIDAS)
Future<void> _performInitialInventoryCheck() async {
  try {
    final syncManager = await _getInventorySyncManager();
    if (syncManager != null) {
      await syncManager.performQuickSync();
    }
  } catch (e) {
    print('❌ Error en verificación inicial de inventario: $e');
  }
}

Future<void> _performPeriodicInventorySync() async {
  try {
    final syncManager = await _getInventorySyncManager();
    if (syncManager != null) {
      await syncManager.performFullInventorySync();
    }
  } catch (e) {
    print('❌ Error en sincronización periódica: $e');
  }
}

Future<void> _performQuickInventorySync() async {
  try {
    final syncManager = await _getInventorySyncManager();
    if (syncManager != null) {
      await syncManager.performQuickSync();
    }
  } catch (e) {
    print('❌ Error en sincronización rápida: $e');
  }
}

Future<InventorySyncManager?> _getInventorySyncManager() async {
  try {
    final odooService = OdooServiceEnhanced(
      baseUrl: ApiConfig.baseUrl,
      dbName: ApiConfig.dbName,
    );
    
    final loggedIn = await odooService.login('admin', 'admin');
    if (loggedIn) {
      final inventoryService = OdooInventoryService(odooService);
      final productService = OdooProductService(odooService);
      return InventorySyncManager(inventoryService, productService);
    }
  } catch (e) {
    print('❌ Error creando InventorySyncManager: $e');
  }
  return null;
}

// ✅ FUNCIÓN _buildErrorApp
Widget _buildErrorApp(String errorMessage) {
  return MaterialApp(
    home: Scaffold(
      backgroundColor: Colors.red[50],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 20),
              const Text(
                'Error de Inicialización', 
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  errorMessage, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () => main(),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PointSales App',
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black),
          displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black),
          displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
          headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal, color: Colors.black),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.black87),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.black54,
          showUnselectedLabels: true,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          hintStyle: const TextStyle(color: Colors.black54),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LogoScreens(),
        '/login': (context) => const FormScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/home_screen': (context) => const HomeScreen(),
        '/profile_screen': (context) => const ProfileScreen(),
        '/map_screen': (context) => PlaceSearchScreen(),
        '/empty_home': (context) => const Scaffold(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/client_screen':
            return MaterialPageRoute(
              builder: (context) => ClientScreen(
                onCustomerPageNavigate: (Customer customer) => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrdenPago(  
                      customer: customer,
                      onProductListNavigate: (Customer selectedCustomer) => Navigator.push( 
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductList(selectedCustomer: selectedCustomer), 
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            
          case '/success_screen':
            final args = settings.arguments as List<Map<String, dynamic>>;
            return MaterialPageRoute(
              builder: (context) => SuccessfullScreen(purchaseHistory: args),
            );
            
          case '/purchase_history':
            final args = settings.arguments as List<Map<String, dynamic>>?;
            return MaterialPageRoute(
              builder: (context) => PurchaseHistory(purchaseHistory: args ?? []),
            );
            
          case '/orden_compra_page':
            final customer = settings.arguments as Customer;
            return MaterialPageRoute(
              builder: (context) => OrdenPago(
                customer: customer,
                onProductListNavigate: (Customer selectedCustomer) => Navigator.push( 
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductList(selectedCustomer: selectedCustomer), 
                  ),
                ),
              ),
            );
            
          default:
            return MaterialPageRoute(
              builder: (context) => const HomeScreen(),
            );
        }
      },
    );
  }
  
}