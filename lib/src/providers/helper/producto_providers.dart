// product_provider.dart
import 'package:flutter/material.dart';
import 'package:ecomerce_app/src/domain/models/products_model.dart';
import 'package:ecomerce_app/src/data/api_repository/databaseHelper.dart';
import 'package:ecomerce_app/src/providers/navigator.dart';


class ProductProvider with ChangeNotifier {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final NavigationService? _navigationService;
  List<Product> _products = [];
  bool _isLoading = false;

  ProductProvider([this._navigationService]);

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> loadProducts() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      _products = await _dbHelper.getProducts();
    } catch (e) {
      _navigationService?.goBack();
      throw Exception('Error al cargar productos: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addProduct(Product product) async {
    try {
      await _dbHelper.insertProduct(product);
      await loadProducts();
      
      _navigationService?.navigateTo('/products');
      return true;
    } catch (e) {
      print('Error al agregar producto: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.update(
        'Products', // ✅ Asegúrate que esta tabla existe
        product.toMap(), // ✅ Ahora existe toMap
        where: 'id = ?',
        whereArgs: [product.id],
      );
      
      if (count > 0) {
        await loadProducts();
        return true;
      }
      return false;
    } catch (e) {
      print('Error al actualizar producto: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    try {
      final db = await _dbHelper.database;
      final count = await db.delete(
        'Products',
        where: 'id = ?',
        whereArgs: [id],
      );
      
      if (count > 0) {
        await loadProducts();
        return true;
      }
      return false;
    } catch (e) {
      print('Error al eliminar producto: $e');
      return false;
    }
  }

  void navigateToCreate() {
    _navigationService?.navigateTo('/product/create');
  }
}
