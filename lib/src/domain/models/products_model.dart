import 'dart:convert';

class Product {
  int? id;
  String? title;
  double? price;
  String? description;
  String? category;
  String? image;
  Rating? rating;
  bool isSelected;
  int quantity; // Nueva propiedad quantity

  Product({
    this.id,
    this.title,
    this.price,
    this.description,
    this.category,
    this.image,
    this.rating,
    this.isSelected = false,
    this.quantity = 1, // Valor por defecto para quantity
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'price': price,
      'description': description,
      'category': category,
      'image': image,
      'rating': rating?.toMap(),
      'isSelected': isSelected,
      'quantity': quantity, // Agregar quantity al mapa
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id']?.toInt(),
      title: map['title'],
      price: map['price']?.toDouble(),
      description: map['description'],
      category: map['category'],
      image: map['image'],
      rating: map['rating'] != null ? Rating.fromMap(map['rating']) : null,
      isSelected: map['isSelected'] ?? false,
      quantity: map['quantity']?.toInt() ?? 1, // Obtener quantity del mapa
    );
  }

  String toJson() => json.encode(toMap());

  factory Product.fromJson(String source) => Product.fromMap(json.decode(source));
}

class Rating {
  double? rate;
  int? count;

  Rating({
    this.rate,
    this.count,
  });

  Map<String, dynamic> toMap() {
    return {
      'rate': rate,
      'count': count,
    };
  }

  factory Rating.fromMap(Map<String, dynamic> map) {
    return Rating(
      rate: map['rate']?.toDouble(),
      count: map['count']?.toInt(),
    );
  }
}
