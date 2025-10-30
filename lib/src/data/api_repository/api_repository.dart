 import 'dart:convert';
 import 'package:ecomerce_app/src/domain/models/products_model.dart';
 import 'package:ecomerce_app/src/domain/models/users_model.dart';
 import 'package:http/http.dart' as http;

 class ApiServices {
   final String baseUrl = 'https://fakestoreapi.com';

//Método para obtener todos los productos
 Future<List<Product>> fetchAllProducts() async {
     final response = await http.get(Uri.parse('$baseUrl/products'));

     if (response.statusCode == 200) {
       List<dynamic> jsonResponse = json.decode(response.body);
       return jsonResponse.map((product) => Product.fromMap(product)).toList();
     } else {
       throw Exception('Error al cargar los productos');
     }
  }

   // Método para obtener todos los usuarios
   Future<List<User>> fetchAllUsers() async {
     final response = await http.get(Uri.parse('$baseUrl/users'));

     if (response.statusCode == 200) {
       List<dynamic> jsonResponse = json.decode(response.body);
       return jsonResponse.map((user) => User.fromMap(user)).toList();
     } else {
       throw Exception('Error al cargar los usuarios');
     }
   }
}


// // lib/src/data/api_repository/api_repository.dart
// import 'package:ecomerce_app/src/domain/models/products_model.dart';
// import 'package:ecomerce_app/src/domain/models/users_model.dart';
// import './point_sales_service.dart';
// import './point_sales_product_service.dart';
// import './point_sales_user_service.dart';
// import './point_sales_order_service.dart';

// class ApiServices {
//   late final PointSalesService _pointSalesService;
//   late final PointSalesProductService _productService;
//   late final PointSalesUserService _userService;
//   late final PointSalesOrderService _orderService;

//   ApiServices() {
//     _pointSalesService = PointSalesService();
//     _productService = PointSalesProductService(_pointSalesService);
//     _userService = PointSalesUserService(_pointSalesService);
//     _orderService = PointSalesOrderService(_pointSalesService);
//   }

//   // ✅ Inicializar servicio
//   Future<void> initialize() async {
//     await _pointSalesService.loadTokens();
    
//     // Si no hay token válido, hacer login con credenciales por defecto
//     if (!_pointSalesService.isTokenValid) {
//       await _pointSalesService.login();
//     }
//   }

//   // ✅ Método para obtener todos los productos
//   Future<List<Product>> fetchAllProducts() async {
//     return await _productService.fetchAllProducts();
//   }

//   // ✅ Método para obtener todos los usuarios
//   Future<List<User>> fetchAllUsers() async {
//     return await _userService.fetchAllUsers();
//   }

//   // ✅ Login personalizado
//   Future<bool> login(String username, String password) async {
//     return await _pointSalesService.login(
//       username: username,
//       password: password,
//     );
//   }

//   // ✅ Crear orden
//   Future<Order> createOrder(Order order) async {
//     return await _orderService.createOrder(order);
//   }

//   // ✅ Crear usuario
//   Future<User> createUser(User user) async {
//     return await _userService.createUser(user);
//   }

//   // ✅ Cerrar sesión
//   Future<void> logout() async {
//     await _pointSalesService.logout();
//   }

//   // ✅ Verificar estado de autenticación
//   bool get isAuthenticated => _pointSalesService.isTokenValid;
// }