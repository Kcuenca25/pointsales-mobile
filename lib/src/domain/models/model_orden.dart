import 'users_model.dart';

class Order {
  final String id;
  final DateTime date;
  final String status;
  final double total;
  final User? usuario;       // <-- cliente que hizo la orden
  final String? articulo;    // <-- producto/artículo de la orden

  Order({
    required this.id,
    required this.date,
    required this.status,
    required this.total,
    this.usuario,
    this.articulo,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'].toString(),
      date: DateTime.parse(json['date']),
      status: json['status'],
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      usuario: json['usuario'] != null ? User.fromJson(json['usuario']) : null,
      articulo: json['articulo'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'status': status,
      'total': total,
      'usuario': usuario?.toJson(),
      'articulo': articulo,
    };
  }
}
