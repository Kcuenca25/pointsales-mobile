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
}