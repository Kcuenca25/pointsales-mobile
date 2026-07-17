// lib/models/odoo_config.dart
class OdooConfig {
  final String id;
  final String domain;
  final String dbName;
  final String companyName;
  final String username;
  final String password;
  final String odooVersion;
  final DateTime createdAt;
  bool isActive;

  OdooConfig({
    String? id,
    required this.domain,
    required this.dbName,
    required this.companyName,
    required this.username,
    required this.password,
    this.odooVersion = '19.0',
    DateTime? createdAt,
    this.isActive = true,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'domain': domain,
    'dbName': dbName,
    'companyName': companyName,
    'username': username,
    'password': password,
    'odooVersion': odooVersion,
    'createdAt': createdAt.toIso8601String(),
    'isActive': isActive,
  };

  factory OdooConfig.fromJson(Map<String, dynamic> json) => OdooConfig(
    id: json['id'],
    domain: json['domain'],
    dbName: json['dbName'],
    companyName: json['companyName'],
    username: json['username'],
    password: json['password'],
    odooVersion: json['odooVersion'],
    createdAt: DateTime.parse(json['createdAt']),
    isActive: json['isActive'],
  );
}
