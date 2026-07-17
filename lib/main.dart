import 'package:ecomerce_app/src/presentation/screens/seccessfull_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; 
import 'package:ecomerce_app/src/presentation/screens/product/product_list.dart';
import 'package:ecomerce_app/src/presentation/screens/user/orden_de_page.dart';
import 'package:ecomerce_app/src/presentation/screens/user/home_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/02-client_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/04-purchase_history.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen/05-profile_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/botton_navigation_bar_screen//06-maps.dart';
import 'package:ecomerce_app/src/presentation/screens/forms/form_screen.dart';
import 'package:ecomerce_app/src/presentation/screens/forms/forgot_password_screen.dart';
import 'package:ecomerce_app/src/data/api_repository/databaseHelper.dart' as db;
import 'package:ecomerce_app/src/providers/helper/producto_providers.dart';
import 'package:ecomerce_app/src/providers/helper/usuario_providers.dart';
import 'package:ecomerce_app/src/providers/navigator.dart';//import 'package:ecomerce_app/src/presentation/screens/logo_screens.dart';
import 'package:ecomerce_app/src/domain/models/customer_model.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_auth_service.dart';
import 'package:ecomerce_app/src/services/connectivity_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:ecomerce_app/src/screens/onboarding_screen.dart';
import 'package:ecomerce_app/src/services/offline_order_service.dart';
import 'package:ecomerce_app/src/services/service_company.dart';
import 'package:ecomerce_app/src/domain/models/proveedores.dart';
import 'package:ecomerce_app/src/data/api_repository/odooProveedorService.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:ecomerce_app/src/screens/CompanyLogoScreen.dart';
import 'package:ecomerce_app/src/screens/OnboardingStep1Screen.dart';
import 'package:ecomerce_app/src/screens/SelectCompanyScreen.dart';//import 'package:ecomerce_app/src/domain/models/odoo_config.dart';
import 'package:ecomerce_app/src/screens/credentials_screen.dart';
import 'package:ecomerce_app/src/screens/onboarding_step2_screen.dart';
import 'package:ecomerce_app/src/config/api_config.dart';

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

  runApp(
    FutureBuilder(
      future: initializeApp(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: const Color.fromARGB(228, 126, 186, 194),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return _buildErrorApp('Error de inicialización: ${snapshot.error}');
        }

        return buildMainApp();
      },
    ),
  );
}

Future<void> initializeApp() async {
  print('🚀 Iniciando aplicación...');
  
  // 1. Inicializar Hive
  await Hive.initFlutter();
  await Hive.openBox<Map>('offline_orders');
  await Hive.openBox<Map>('cached_customers');
  await Hive.openBox<Map>('cached_products');
  
  // 2. Inicializar base de datos local
  await db.DatabaseHelper().database;
  print('✅ Base de datos local inicializada');

  // 🎯 3. VERIFICAR SI HAY DOMINIO GUARDADO
  final prefs = await SharedPreferences.getInstance();
  final savedDomain = prefs.getString('odoo_domain');
  
  print('🎯 Dominio guardado: ${savedDomain ?? "NO"}');
  
  // 4. Inicializar CompanyService SOLO si hay dominio
  if (savedDomain != null) {
    if (savedDomain.contains('trycloudflare.com')) {
      ApiConfig.baseUrl = 'https://lmhlast.tailorw.net';
      prefs.setString('odoo_domain', 'lmhlast.tailorw.net');
      print('🔄 Redirigiendo túnel Cloudflare expirado a producción: lmhlast.tailorw.net');
    } else {
      ApiConfig.baseUrl = 'https://$savedDomain';
    }
    
    // ✅ CARGAR CREDENCIALES GLOBALES PARA EVITAR ERRORES DE RELOGIN EN OTRAS PANTALLAS
    final savedUsername = prefs.getString('username') ?? prefs.getString('userName') ?? prefs.getString('current_user') ?? '';
    final savedPassword = prefs.getString('session_password') ?? prefs.getString('password') ?? 'A001admin';
    ApiConfig.defaultUsername = savedUsername;
    ApiConfig.defaultPassword = savedPassword;

    print('🏢 Inicializando CompanyService...');
    await CompanyService().initialize();
    print('✅ CompanyService inicializado');
    
    // Pre-cargar proveedores (temporalmente comentado si da error)
    // print('🚀 Pre-cargando proveedores...');
    // ProveedorCache.preloadProveedores().ignore();
    
    // Configurar sincronización automática
    _initAutoSync();
  }
  
  print('🎯 Todos los servicios inicializados correctamente');
}

Future<String> _determineInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  
  final hasDomain = prefs.getString('odoo_domain') != null;
  final hasDatabase = prefs.getString('odoo_database') != null;
  final hasCredentials = prefs.getInt('current_uid') != null && 
                        prefs.getString('session_password') != null;
  
  print('🎯 Determinar ruta inicial:');
  print('   🏢 Dominio: ${hasDomain ? "SÍ" : "NO"}');
  print('   💾 Base de datos: ${hasDatabase ? "SÍ" : "NO"}');
  print('   🔑 Credenciales completas: ${hasCredentials ? "SÍ" : "NO"}');
  
  // 🎯 FLUJO SECUENCIAL CORREGIDO:
  // 1. PRIMERA VEZ: Dominio y BD
  if (!hasDomain) {
    print('   → Ir a: /onboarding-step1 (sin dominio)');
    return '/onboarding-step1';
  } 
  
  if (!hasDatabase) {
    print('   → Ir a: /onboarding-step2 (sin BD)');
    return '/onboarding-step2';
  } 
  
  // 2. INICIO DE SESIÓN REQUERIDO AL INICIAR LA APP (según flujo solicitado: Login -> Select Company)
  print('   → Ir a: /credentials (mostrando login antes de selección)');
  return '/credentials';
}

Widget buildMainApp() {
  return FutureBuilder<String>(
    future: _determineInitialRoute(),
    builder: (context, snapshot) {
      print('===================================');
      print('🎯 DEBUG _buildMainApp:');
      print('   snapshot.connectionState: ${snapshot.connectionState}');
      
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const MaterialApp(
          home: Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        );
      }
      
      if (snapshot.hasError) {
        return _buildErrorApp('Error determinando ruta inicial: ${snapshot.error}');
      }
      
      final initialRoute = snapshot.data ?? '/onboarding-step1';
      print('   🌐 initialRoute será: $initialRoute');
      print('===================================');
      
      // Obtener dominio para el servicio Odoo
      String? savedDomain;
      SharedPreferences.getInstance().then((prefs) {
        savedDomain = prefs.getString('odoo_domain');
      });
      
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
          ChangeNotifierProvider<CompanyService>(
            create: (_) => CompanyService(),
          ),
          
          Provider<OdooAuthService>(create: (_) => OdooAuthService()),
          Provider<OdooServiceEnhanced>(
            create: (_) {
              if (savedDomain != null) {
                return OdooServiceEnhanced(
                  baseUrl: 'https://$savedDomain',
                  dbName: 'pointsales-v18', // Se actualizará en OnboardingStep2
                );
              }
              return OdooServiceEnhanced(
                baseUrl: ApiConfig.baseUrl,
                dbName: 'pointsales-v18',
              );
            },
          ),
        ],
        child: MaterialApp(
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
          // 🎯 PUNTO DE ENTRADA DIRECTO AL FLUJO SECUENCIAL
          initialRoute: initialRoute,
          routes: {
            // 🎯 FLUJO SECUENCIAL COMPLETO
            '/onboarding-step1': (context) => OnboardingStep1Screen(),
            '/onboarding-step2': (context) => const OnboardingStep2Screen(),
            '/credentials': (context) => const CredentialsScreen(),
            '/select-company': (context) => const SelectCompanyScreen(),
            '/company-logo': (context) => const CompanyLogoScreen(),
            
            // 🎯 PANTALLA PRINCIPAL
            '/home_screen': (context) => const HomeScreen(),
            
            // 🎯 RUTAS EXISTENTES (mantener compatibilidad)
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const FormScreen(),
            '/forgot_password': (context) => const ForgotPasswordScreen(),
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
        ),
      );
    },
  );
}

void _initAutoSync() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    print('🔄 Verificando sincronización al iniciar...');
    await OfflineOrderService.checkAndSync();
  });
  
  ConnectivityService.onConnectivityChanged.listen((result) async {
    final tieneInternet = await ConnectivityService.hasInternet();
    if (tieneInternet) {
      print('🌐 Conexión recuperada - Sincronizando órdenes pendientes...');
      await OfflineOrderService.syncPendingOrders();
    }
  });
  
  print('✅ Sincronización automática configurada');
}

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
