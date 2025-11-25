import 'package:ecomerce_app/src/domain/models/products_model.dart';

class ArticuloItem {
  final int id;
  final String nombre;
  final String categoria;
  final String? subcategoria;
  final double precio;
  final String descripcion;
  final String? imagen;
  final double? rating;
  final int? reviews;
  int cantidad;

  ArticuloItem({
    required this.id,
    required this.nombre,
    required this.categoria,
    this.subcategoria,
    required this.precio,
    required this.descripcion,
    this.imagen,
    this.rating,
    this.reviews,
    this.cantidad = 1,
  });

  // ✅ MÉTODO COPYWITH PARA ACTUALIZAR DESDE PRODUCTO ODDO
  ArticuloItem copyWithProduct(Product product) {
    return ArticuloItem(
      id: id,
      nombre: product.name, // ✅ ACTUALIZAR NOMBRE
      categoria: product.categoryName ?? categoria, // ✅ ACTUALIZAR CATEGORÍA
      subcategoria: product.typeDisplay, // ✅ ACTUALIZAR SUBCATEGORÍA
      precio: product.listPrice, // ✅ ACTUALIZAR PRECIO
      descripcion: product.description ?? descripcion, // ✅ ACTUALIZAR DESCRIPCIÓN
      imagen: imagen,
      rating: rating,
      reviews: reviews,
      cantidad: cantidad,
    );
  }

  // ✅ MÉTODO COPYWITH GENERAL
  ArticuloItem copyWith({
    int? id,
    String? nombre,
    String? categoria,
    String? subcategoria,
    double? precio,
    String? descripcion,
    String? imagen,
    double? rating,
    int? reviews,
    int? cantidad,
  }) {
    return ArticuloItem(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoria: categoria ?? this.categoria,
      subcategoria: subcategoria ?? this.subcategoria,
      precio: precio ?? this.precio,
      descripcion: descripcion ?? this.descripcion,
      imagen: imagen ?? this.imagen,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      cantidad: cantidad ?? this.cantidad,
    );
  }
}