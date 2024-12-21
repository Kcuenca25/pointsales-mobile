import 'dart:convert';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/domain/models/users_model.dart';
import 'package:http/http.dart' as http;

class ApiServices {
  final String baseUrl = 'https://fakestoreapi.com';

  // Método para obtener todos los productos
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
