// lib/src/domain/models/customer_model.dart
import 'dart:convert';

class Customer {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? mobile;
  final String? street;
  final String? city;
  final String? zip;
  final List<dynamic>? country;
  final String? commercialCompanyName;
  final String? vat;
  final String? companyType;
  final bool isCompany;
  final List<dynamic>? countryId;

  Customer({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.mobile,
    this.street,
    this.city,
    this.zip,
    this.country, 
    this.commercialCompanyName,
    this.vat,
    this.companyType,
    this.isCompany = false,
    this.countryId,
  });

  // ✅ CONSTRUCTOR DESDE ODDO (IMPORTANTE)
  factory Customer.fromOdooMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id']?.toInt() ?? 0,
      name: map['name'] ?? 'Sin nombre',
      email: map['email'],
      phone: _parsePhone(map['phone']),
      mobile: _parsePhone(map['mobile']),
      street: map['street'],
      city: map['city'],
      zip: map['zip'],
      commercialCompanyName: _parseCommercialCompanyName(map['commercial_company_name']),
      vat: map['vat'],
      companyType: map['company_type'],
      isCompany: map['is_company'] ?? false,
      countryId: map['country_id'],
    );
  }
   static String? _parsePhone(dynamic value) {
    if (value == null || value == false) return null;
    return value.toString();
  }

  static String? _parseCommercialCompanyName(dynamic value) {
    if (value == null || value == false) return null;
    return value.toString();
  }


  // ✅ Para base de datos local (si es necesario)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'mobile': mobile,
      'street': street,
      'city': city,
      'zip': zip,
      'commercial_company_name': commercialCompanyName,
      'vat': vat,
      'company_type': companyType,
      'is_company': isCompany ? 1 : 0,
      'country_id': countryId != null ? json.encode(countryId) : null,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id']?.toInt() ?? 0,
      name: map['name'] ?? '',
      email: map['email'],
      phone: map['phone'],
      mobile: map['mobile'],
      street: map['street'],
      city: map['city'],
      zip: map['zip'],
      commercialCompanyName: map['commercial_company_name'],
      vat: map['vat'],
      companyType: map['company_type'],
      isCompany: map['is_company'] == 1,
      countryId: map['country_id'] != null ? json.decode(map['country_id']) : null,
    );
  }

  String toJson() => json.encode(toMap());
  factory Customer.fromJson(String source) => Customer.fromMap(json.decode(source));

  // ✅ Métodos útiles
  String get displayName {
    if (commercialCompanyName != null && commercialCompanyName!.isNotEmpty) {
      return '$name (${commercialCompanyName!})';
    }
    return name;
  }

  String get primaryPhone => phone ?? mobile ?? '';

  String get fullAddress {
    final parts = [street, city, zip].where((part) => part != null && part!.isNotEmpty).toList();
    return parts.join(', ');
  }

  // ✅ Para mostrar en UI
  String get typeDescription => isCompany ? 'Empresa' : 'Persona';

  // ✅ Para búsqueda
 bool matchesQuery(String query) {
  final searchTerm = query.toLowerCase();
  return name.toLowerCase().contains(searchTerm) ||
      (email?.toLowerCase().contains(searchTerm) ?? false) ||
      (phone?.toLowerCase().contains(searchTerm) ?? false) ||
      (mobile?.toLowerCase().contains(searchTerm) ?? false) ||
      (commercialCompanyName?.toLowerCase().contains(searchTerm) ?? false) ||
      (city?.toLowerCase().contains(searchTerm) ?? false);
}

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Customer(id: $id, name: $name, email: $email, company: $commercialCompanyName)';
  }
}