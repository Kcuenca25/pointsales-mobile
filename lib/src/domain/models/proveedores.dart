
class Proveedor {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? vat;
  final String? street;
  final String? city;
  final String? zip;
  final String? mobile;
  final bool isCompany;

  Proveedor({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.vat,
    this.street,
    this.city,
    this.zip,
    this.mobile,
    this.isCompany = true,
  });

  factory Proveedor.fromJson(Map<String, dynamic> json) {
    return Proveedor(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      vat: json['vat'] as String?,
      street: json['street'] as String?,
      city: json['city'] as String?,
      zip: json['zip'] as String?,
      mobile: json['mobile'] as String?,
      isCompany: json['is_company'] as bool? ?? true,
    );
  }

  // Método para buscar
  bool matchesQuery(String query) {
    final queryLower = query.toLowerCase();
    return name.toLowerCase().contains(queryLower) ||
        (email?.toLowerCase().contains(queryLower) ?? false) ||
        (phone?.toLowerCase().contains(queryLower) ?? false) ||
        (vat?.toLowerCase().contains(queryLower) ?? false);
  }
}

// 🎯 CLASE PURCHASE ORDER
class PurchaseOrder {
  final String id;
  final DateTime date;
  final double total;
  final String status;

  PurchaseOrder({
    required this.id,
    required this.date,
    required this.total,
    required this.status,
  });
}