// company_service.dart
import 'package:ecomerce_app/src/data/api_repository/odoo_service_enhanced.dart';
class CompanyService {
  static final CompanyService _instance = CompanyService._internal();
  factory CompanyService() => _instance;
  CompanyService._internal();

  String? _companyName;
  String? _userName;
  OdooServiceEnhanced? _odooService;
  bool _isInitialized = false;

  // ✅ INICIALIZAR EL SERVICIO UNA SOLA VEZ
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _odooService = OdooServiceEnhanced(
        baseUrl: 'https://pointsalesqa.tailorw.net',
        dbName: 'pointsales_prodv18',
      );
      
      bool isAuthenticated = await _odooService!.login('admin', 'admin');
      if (isAuthenticated) {
        _companyName = _odooService!.companyName ?? 'EMPRESA NO CONFIGURADA';
        _userName = _odooService!.username ?? 'Admin';
        _isInitialized = true;
        print('🏢 CompanyService inicializado: $_companyName - $_userName');
      } else {
        _companyName = 'ERROR DE CONEXIÓN';
        _userName = 'Usuario';
      }
    } catch (e) {
      _companyName = 'ERROR DE CONEXIÓN';
      _userName = 'Usuario';
      print('❌ Error inicializando CompanyService: $e');
    }
  }

  // ✅ GETTERS PARA ACCEDER A LA INFORMACIÓN
  String get companyName => _companyName ?? 'CARGANDO...';
  String get userName => _userName ?? 'Usuario';
  OdooServiceEnhanced? get odooService => _odooService;
  bool get isInitialized => _isInitialized;

  // ✅ ACTUALIZAR INFORMACIÓN
  void updateCompanyInfo(String companyName, String userName) {
    _companyName = companyName;
    _userName = userName;
  }
}