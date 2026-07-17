// company_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
import 'package:ecomerce_app/src/config/api_config.dart';
import 'package:flutter/foundation.dart';

class CompanyService extends ChangeNotifier {
  static final CompanyService _instance = CompanyService._internal();
  factory CompanyService() => _instance;
  CompanyService._internal();

  String? _companyName;
  String? _userName;
  OdooServiceEnhanced? _odooService;
  bool _isInitialized = false;

  // ✅ MÉTODO CORREGIDO PARA OBTENER EL NOMBRE REAL DESDE ODDO
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _odooService = OdooServiceEnhanced(
        baseUrl: ApiConfig.baseUrl,
        dbName: ApiConfig.dbName,
      );
      
      bool isAuthenticated = await _odooService!.login(
        ApiConfig.defaultUsername, 
        ApiConfig.defaultPassword
      );
      if (isAuthenticated) {
        // ✅ OBTENER EL NOMBRE REAL DE LA EMPRESA DESDE ODDO
        _companyName = await _getCompanyNameFromOdoo();
        _userName = _odooService!.username ?? 'Admin';
        _isInitialized = true;
        print('🏢 CompanyService inicializado: $_companyName - $_userName');
        notifyListeners(); // ✅ NOTIFICAR CAMBIOS
      } else {
        _companyName = await _getSavedCompanyName(); // Fallback
        _userName = 'Usuario';
        notifyListeners(); // ✅ NOTIFICAR CAMBIOS
      }
    } catch (e) {
      _companyName = await _getSavedCompanyName(); // Fallback
      _userName = 'Usuario';
      print('❌ Error inicializando CompanyService: $e');
      notifyListeners(); // ✅ NOTIFICAR CAMBIOS
    }
  }

   // ✅ OVERRIDE DISPOSE: el singleton NO debe destruirse cuando Provider lo libera
  @override
  void dispose() {
    // No llamamos super.dispose() — el singleton debe vivir toda la sesión
    print('⚠️ CompanyService.dispose() ignorado (singleton protegido)');
  }

  Future<void> clearSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('company_name');
      await prefs.remove('user_name');

      _companyName = 'Cargando...';
      _userName = 'Cargando...';
      _odooService = null;
      _isInitialized = false;

      print('✅ CompanyService: datos de sesión limpiados');
      notifyListeners();
    } catch (e) {
      print('❌ Error limpiando CompanyService: $e');
    }
  }


Future<String> _getSavedCompanyName() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('selected_company_name') ?? prefs.getString('companyName') ?? 'Mi Empresa';
}

 // ✅ MÉTODO PARA OBTENER EL NOMBRE DE LA EMPRESA DESDE ODDO
Future<String> _getCompanyNameFromOdoo() async {
  try {
    // Si ya elegimos una empresa en SelectCompanyScreen, usémosla primero
    final prefs = await SharedPreferences.getInstance();
    final selectedName = prefs.getString('selected_company_name');
    if (selectedName != null && selectedName.isNotEmpty) {
      return selectedName;
    }

    // Buscar la compañía principal en Odoo
    final result = await _odooService!.callKw({
      'model': 'res.company',
      'method': 'search_read',
      'args': [],
      'kwargs': {
        'domain': [],
        'fields': ['id', 'name', 'display_name'],
        'limit': 1,
      },
    });

    if (result is List && result.isNotEmpty) {
      final companyData = result[0];
      final companyName = companyData['name'] ?? companyData['display_name'];
      return companyName.toString();
    }
    
    // Fallback
    return 'Mi Empresa';
  } catch (e) {
    print('❌ Error obteniendo nombre de compañía desde Odoo: $e');
    // Fallback
    return 'Mi Empresa';
  }
}

  // ✅ GETTERS PARA ACCEDER A LA INFORMACIÓN
  String get companyName => _companyName ?? 'Mi Empresa';
  String get userName => _userName ?? 'Usuario';
  OdooServiceEnhanced? get odooService => _odooService;
  bool get isInitialized => _isInitialized;

  // ✅ ACTUALIZAR INFORMACIÓN
  void updateCompanyInfo(String companyName, String userName) {
    _companyName = companyName;
    _userName = userName;
    notifyListeners(); // ✅ NOTIFICAR CAMBIOS
  }
  
  // ✅ MÉTODO PARA OBTENER LA INSTANCIA
  static CompanyService get instance => _instance;
  
  // ✅ MÉTODO PARA FORZAR ACTUALIZACIÓN
  Future<void> refreshCompanyName() async {
    _companyName = await _getCompanyNameFromOdoo();
    notifyListeners(); // ✅ NOTIFICAR CAMBIOS
  }
}
