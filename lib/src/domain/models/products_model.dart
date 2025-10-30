import 'package:flutter/material.dart'; // ✅ AGREGAR ESTA IMPORTACIÓN
import 'dart:convert';

class Product {
  final int id;
  final String name;
  final String? defaultCode;
  final String? barcode; // ✅ AGREGAR
  final double listPrice;
  final double? standardPrice; // ✅ AGREGAR - Costo
  final String type;
  final int? categoryId;
  final String? categoryName;
  final String? description;
  final List<dynamic>? taxesIds; // Impuestos de venta
  final List<dynamic>? supplierTaxesIds; // Impuestos de compra
  final String? category; // Alias para categ_id
  
  String get title => name;
  double get price => listPrice;
  bool isSelected = false;
  int quantity = 1;

    String get safeDefaultCode => defaultCode ?? '';
  String get safeBarcode => barcode ?? '';
  String get safeCategory => category ?? '';
  String get safeCategoryName => categoryName ?? '';


  String? image;
  double? ratingRate;
  int? ratingCount;

  Product({
    required this.id,
    required this.name,
     this.defaultCode,
    this.barcode, // ✅ AGREGAR
    required this.listPrice,
    this.standardPrice, // ✅ AGREGAR
    required this.type,
    this.categoryId,
    this.categoryName,
    this.description = '',
    this.category = '',
    this.image,
    this.ratingRate,
    this.ratingCount,
    this.taxesIds,
    this.supplierTaxesIds,
  });

  // ✅ GETTER para tipo de producto legible
   String get typeDisplay {
    final safeType = type; // type debería ser required, pero por si acaso
    switch (safeType) {
      case 'consu':
        return 'Consumible';
      case 'service':
        return 'Servicio';
      case 'product':
        return 'Almacenable';
      default:
        return safeType ?? 'Desconocido';
    }
  }

  // ✅ GETTER para saber si se vende
 bool get isSellable {
    final safeType = type;
    return safeType == 'consu' || safeType == 'product';
  }

  // ✅ GETTER para color según tipo
  Color get typeColor {
    final safeType = type;
    switch (safeType) {
      case 'consu':
        return Colors.green;
      case 'service':
        return Colors.blue;
      case 'product':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // ✅ MÉTODO toMap PARA LA BASE DE DATOS
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': name,
      'price': listPrice,
      'description': description ?? '',
      'category': category ?? categoryName ?? '',
      'image': image,
      'barcode': barcode ?? defaultCode,
      'rating_rate': ratingRate,
      'rating_count': ratingCount,
      'standard_price': standardPrice, // ✅ AGREGAR
      // Campos específicos de Odoo
      'name': name,
      'default_code': defaultCode,
      'list_price': listPrice,
      'type': type,
      'category_id': categoryId,
      'category_name': categoryName,
      'taxes_id': taxesIds,
      'supplier_taxes_id': supplierTaxesIds,
    };
  }

  // ✅ MÉTODO fromMap PARA LA BASE DE DATOS
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int,
      name: map['name'] as String? ?? map['title'] as String? ?? 'Sin nombre',
      defaultCode: map['default_code'] as String? ?? map['barcode'] as String? ?? '',
      barcode: map['barcode'] as String?,
      listPrice: (map['list_price'] as num?)?.toDouble() ?? 
                (map['price'] as num?)?.toDouble() ?? 0.0,
      standardPrice: (map['standard_price'] as num?)?.toDouble(), // ✅ AGREGAR
      type: map['type'] as String? ?? 'consu',
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String? ?? map['category'] as String?,
      description: map['description'] as String?,
      category: map['category'] as String?,
      image: map['image'] as String?,
      ratingRate: (map['rating_rate'] as num?)?.toDouble(),
      ratingCount: map['rating_count'] as int?,
      taxesIds: map['taxes_id'] as List<dynamic>?,
      supplierTaxesIds: map['supplier_taxes_id'] as List<dynamic>?,
    );
  }

  // ✅ MÉTODO fromJson PARA ODDO
  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['categ_id'] as List?;
    final taxesIds = json['taxes_id'] as List?;
    final supplierTaxesIds = json['supplier_taxes_id'] as List?;
    
    return Product(
      id: json['id'] as int,
      name: json['name'] as String,
      defaultCode: json['default_code'] as String? ?? '',
      barcode: json['barcode'] as String?,
      listPrice: (json['list_price'] as num?)?.toDouble() ?? 0.0,
      standardPrice: (json['standard_price'] as num?)?.toDouble(), // ✅ AGREGAR
      type: json['type'] as String? ?? 'consu',
      categoryId: category?[0] as int?,
      categoryName: category?[1] as String?,
      description: json['description'] as String? ?? '',
      category: category?[1] as String? ?? 'Sin categoría',
      taxesIds: taxesIds,
      supplierTaxesIds: supplierTaxesIds,
    );
  }

  // ✅ MÉTODO PARA CONVERTIR DE PRODUCTO ODDO A FORMATO LOCAL
  factory Product.fromOdoo(Map<String, dynamic> odooProduct) {
    final category = odooProduct['categ_id'] as List?;
    final taxesIds = odooProduct['taxes_id'] as List?;
    final supplierTaxesIds = odooProduct['supplier_taxes_id'] as List?;
    
    return Product(
      id: odooProduct['id'] as int,
      name: odooProduct['name'] as String,
      defaultCode: odooProduct['default_code'] as String? ?? '',
      barcode: odooProduct['barcode'] as String?,
      listPrice: (odooProduct['list_price'] as num?)?.toDouble() ?? 0.0,
      standardPrice: (odooProduct['standard_price'] as num?)?.toDouble(), // ✅ AGREGAR
      type: odooProduct['type'] as String? ?? 'consu',
      categoryId: category?[0] as int?,
      categoryName: category?[1] as String?,
      description: odooProduct['description'] as String? ?? '',
      category: category?[1] as String? ?? 'Sin categoría',
      taxesIds: taxesIds,
      supplierTaxesIds: supplierTaxesIds,
    );
  }
}