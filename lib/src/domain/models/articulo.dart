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
  final bool tieneImpuestos; 

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
    this.tieneImpuestos = false,
    
  });

    Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'subcategoria': subcategoria,
      'precio': precio,
      'descripcion': descripcion,
      'cantidad': cantidad,
      'imagen': imagen,
      'rating': rating,
      'reviews': reviews,
      'tieneImpuestos': tieneImpuestos,
    };
  }
  // ✅ AGREGA ESTE FACTORY
  factory ArticuloItem.fromJson(Map<String, dynamic> json) {
    return ArticuloItem(
      id: json['id'] ?? 0,
      nombre: json['nombre'] ?? '',
      categoria: json['categoria'] ?? '',
      subcategoria: json['subcategoria'] ?? '',
      precio: (json['precio'] ?? 0.0).toDouble(),
      descripcion: json['descripcion'] ?? '',
      cantidad: json['cantidad'] ?? 1,
      imagen: json['imagen'] ?? 'default_product',
      rating: (json['rating'] ?? 4.0).toDouble(),
      reviews: json['reviews'] ?? 0,
      tieneImpuestos: json['tieneImpuestos'] ?? false,
    );
  }

  ArticuloItem copyWithProduct(Product product) {
    return ArticuloItem(
      id: id,
      nombre: product.name,
      categoria: product.categoryName ?? categoria,
      subcategoria: product.typeDisplay,
      precio: product.listPrice,
      descripcion: product.description ?? descripcion,
      cantidad: cantidad,
      imagen: imagen,
      rating: rating,
      reviews: reviews,
      tieneImpuestos: tieneImpuestos,
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
