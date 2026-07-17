// session_provider.dart
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:flutter/foundation.dart';

class SessionProvider with ChangeNotifier {
  OdooServiceEnhanced? _odooService;
  String? _companyName;
  String? _userName;

  void setOdooService(OdooServiceEnhanced service) {
    _odooService = service;
    _companyName = service.getCompanyName();
    notifyListeners();
  }

  void login(String username, String companyName) {
    _userName = username;
    _companyName = companyName;
    notifyListeners();
  }

  void logout() {
    _userName = null;
    _companyName = null;
    _odooService = null;
    notifyListeners();
  }

  String? get companyName => _companyName;
  String? get userName => _userName;
  bool get isLoggedIn => _companyName != null;
}
